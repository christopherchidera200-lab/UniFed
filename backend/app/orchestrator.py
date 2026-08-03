"""Fan-out orchestration.

Two execution modes over one shared implementation:

  * ``run_investigation``    — blocking; waits for every collector, returns the whole result.
  * ``stream_investigation`` — incremental; yields each collector's result the moment it
                               settles, then a final summary.

Streaming exists because collector latency is dominated by the slowest third-party
source. Measured against github.com: four collectors finished in under 4s while
Certificate Transparency (crt.sh) burned the full 15s timeout budget, so a blocking
caller waited 15s for data that was ready in 3.8s. See docs/adr/0005-streaming-investigations.md.

Both modes share ``_prepare`` and ``_finalize`` so validation, collector selection,
scoring and logging can never drift between them.
"""
from __future__ import annotations

import asyncio
import time
import uuid
from collections.abc import AsyncIterator
from datetime import UTC, datetime

from app.collectors import registry
from app.collectors.base import Collector
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


def _prepare(request: InvestigationRequest) -> tuple[str, list[Collector]]:
    """Validate the target and resolve the collector set. Raises on bad input."""
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
    return target, collectors


def _finalize(
    investigation_id: str,
    target: str,
    request: InvestigationRequest,
    results: list[CollectorResult],
    started: float,
) -> InvestigationResponse:
    """Score the collected results and assemble the response envelope."""
    results = [r for r in results if r.status is not CollectorStatus.SKIPPED]
    results.sort(key=lambda r: r.collector)

    risk = score_investigation(results)
    duration_ms = int((time.perf_counter() - started) * 1000)
    findings_count = sum(len(r.findings) for r in results)

    log.info(
        "investigation.complete",
        target=target,
        duration_ms=duration_ms,
        risk_score=risk.score,
        findings=findings_count,
    )

    return InvestigationResponse(
        investigation_id=investigation_id,
        target=target,
        target_type=request.target_type,
        created_at=datetime.now(UTC),
        duration_ms=duration_ms,
        results=results,
        risk=risk,
        findings_count=findings_count,
    )


async def run_investigation(request: InvestigationRequest) -> InvestigationResponse:
    """Run every applicable collector concurrently and return the complete result."""
    started = time.perf_counter()
    target, collectors = _prepare(request)

    # Collector.run never raises — it converts its own failures into a result —
    # so gather() cannot propagate an exception here.
    results: list[CollectorResult] = list(
        await asyncio.gather(*(c.run(target, request.target_type) for c in collectors))
    )

    return _finalize(str(uuid.uuid4()), target, request, results, started)


async def stream_investigation(
    request: InvestigationRequest,
) -> AsyncIterator[tuple[str, CollectorResult | InvestigationResponse | dict[str, object]]]:
    """Yield ``(event_name, payload)`` as each collector settles.

    Event sequence:
        ``started``   exactly once, first — carries the id, target and expected collectors
                      so the UI can render one placeholder card per pending source.
        ``collector`` zero or more, in completion order (fastest first).
        ``complete``  exactly once, last — the full scored InvestigationResponse.

    A ``skipped`` collector is not emitted, matching ``_finalize``'s filtering.

    Cancellation: if the client disconnects, the consumer stops iterating and the
    generator is closed, which cancels the pending collector tasks in the finally
    block rather than leaving them to run detached.
    """
    started = time.perf_counter()
    target, collectors = _prepare(request)
    investigation_id = str(uuid.uuid4())

    yield (
        "started",
        {
            "investigation_id": investigation_id,
            "target": target,
            "target_type": request.target_type.value,
            "collectors": [c.name for c in collectors],
        },
    )

    tasks = {
        asyncio.create_task(c.run(target, request.target_type), name=c.name)
        for c in collectors
    }
    results: list[CollectorResult] = []

    try:
        for coro in asyncio.as_completed(tasks):
            result = await coro
            results.append(result)
            if result.status is not CollectorStatus.SKIPPED:
                yield "collector", result
    finally:
        # Reached on client disconnect (GeneratorExit) as well as normal completion.
        for task in tasks:
            if not task.done():
                task.cancel()

    yield "complete", _finalize(investigation_id, target, request, results, started)
