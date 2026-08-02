"""Fan-out orchestration: run every applicable collector concurrently under a wall-clock budget."""
from __future__ import annotations

import asyncio
import time
import uuid
from datetime import UTC, datetime

from app.collectors import registry
from app.errors import InvalidTarget
from app.logging_config import get_logger
from app.schemas import (
    CollectorResult,
    CollectorStatus,
    InvestigationRequest,
    InvestigationResponse,
)
from app.scoring import score_investigation
from app.validation import validate_target

log = get_logger(__name__)


async def run_investigation(request: InvestigationRequest) -> InvestigationResponse:
    started = time.perf_counter()
    target = validate_target(request.target, request.target_type)

    collectors = registry.select(request.target_type, request.collectors)
    if not collectors:
        raise InvalidTarget(
            f"No collectors available for target type '{request.target_type.value}'"
        )

    log.info(
        "investigation.start",
        target=target,
        target_type=request.target_type.value,
        collectors=[c.name for c in collectors],
    )

    # Each collector already enforces its own timeout; gather cannot raise because
    # Collector.run swallows everything.
    results: list[CollectorResult] = list(
        await asyncio.gather(*(c.run(target, request.target_type) for c in collectors))
    )
    results = [r for r in results if r.status is not CollectorStatus.SKIPPED]
    results.sort(key=lambda r: r.collector)

    risk = score_investigation(results)
    duration_ms = int((time.perf_counter() - started) * 1000)

    log.info(
        "investigation.complete",
        target=target,
        duration_ms=duration_ms,
        risk_score=risk.score,
        findings=sum(len(r.findings) for r in results),
    )

    return InvestigationResponse(
        investigation_id=str(uuid.uuid4()),
        target=target,
        target_type=request.target_type,
        created_at=datetime.now(UTC),
        duration_ms=duration_ms,
        results=results,
        risk=risk,
        findings_count=sum(len(r.findings) for r in results),
    )
