"""DynamoDB item shapes. The single-table key design lives here and nowhere else.

See docs/adr/0002-dynamodb-single-table.md for the access-pattern table.
"""
from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any

from app.schemas import InvestigationResponse

# Retention by tier, in days.
RETENTION_DAYS = {"free": 30, "pro": 365, "enterprise": 1095}


def _ttl(days: int) -> int:
    return int((datetime.now(UTC) + timedelta(days=days)).timestamp())


def investigation_item(
    investigation: InvestigationResponse, user_sub: str, tier: str = "free"
) -> dict[str, Any]:
    created = investigation.created_at.isoformat()
    return {
        "PK": f"INV#{investigation.investigation_id}",
        "SK": "META",
        "GSI1PK": f"USER#{user_sub}",
        "GSI1SK": f"TS#{created}",
        "entity": "investigation",
        "investigation_id": investigation.investigation_id,
        "user_sub": user_sub,
        "target": investigation.target,
        "target_type": investigation.target_type.value,
        "created_at": created,
        "duration_ms": investigation.duration_ms,
        "risk_score": investigation.risk.score,
        "risk_band": investigation.risk.band,
        "findings_count": investigation.findings_count,
        "payload": investigation.model_dump(mode="json"),
        "expires_at": _ttl(RETENTION_DAYS.get(tier, 30)),
    }


def audit_item(user_sub: str, action: str, detail: dict[str, Any]) -> dict[str, Any]:
    now = datetime.now(UTC)
    return {
        "PK": f"AUDIT#{user_sub}#{now.date().isoformat()}",
        "SK": f"TS#{now.isoformat()}",
        "entity": "audit",
        "user_sub": user_sub,
        "action": action,
        "detail": detail,
        "expires_at": _ttl(365),
    }


def cache_key(collector: str, target: str) -> dict[str, str]:
    return {"PK": f"CACHE#{collector}#{target}", "SK": "RESULT"}
