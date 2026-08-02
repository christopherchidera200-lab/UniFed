"""Persistence. Falls back to an in-memory store locally so the API runs with no AWS account."""
from __future__ import annotations

from typing import Any, Protocol

from app.config import get_settings
from app.logging_config import get_logger
from app.schemas import InvestigationResponse, InvestigationSummary
from app.storage.models import audit_item, investigation_item

log = get_logger(__name__)


class Repository(Protocol):
    async def save_investigation(
        self, investigation: InvestigationResponse, user_sub: str, tier: str
    ) -> None: ...

    async def get_investigation(self, investigation_id: str) -> dict[str, Any] | None: ...

    async def list_investigations(
        self, user_sub: str, limit: int = 25
    ) -> list[InvestigationSummary]: ...

    async def record_audit(self, user_sub: str, action: str, detail: dict) -> None: ...


class InMemoryRepository:
    """Local/test backend. Same key semantics as DynamoDB so behaviour matches."""

    def __init__(self) -> None:
        self._items: dict[tuple[str, str], dict[str, Any]] = {}

    async def save_investigation(
        self, investigation: InvestigationResponse, user_sub: str, tier: str = "free"
    ) -> None:
        item = investigation_item(investigation, user_sub, tier)
        self._items[(item["PK"], item["SK"])] = item

    async def get_investigation(self, investigation_id: str) -> dict[str, Any] | None:
        return self._items.get((f"INV#{investigation_id}", "META"))

    async def list_investigations(
        self, user_sub: str, limit: int = 25
    ) -> list[InvestigationSummary]:
        rows = [
            i
            for i in self._items.values()
            if i.get("entity") == "investigation" and i.get("user_sub") == user_sub
        ]
        rows.sort(key=lambda i: i["created_at"], reverse=True)
        return [
            InvestigationSummary(
                investigation_id=r["investigation_id"],
                target=r["target"],
                target_type=r["target_type"],
                created_at=r["created_at"],
                risk_score=r["risk_score"],
                findings_count=r["findings_count"],
            )
            for r in rows[:limit]
        ]

    async def record_audit(self, user_sub: str, action: str, detail: dict) -> None:
        item = audit_item(user_sub, action, detail)
        self._items[(item["PK"], item["SK"])] = item


class DynamoRepository:
    """Production backend. boto3 is sync; calls are pushed to a thread."""

    def __init__(self, table_name: str, region: str) -> None:
        import boto3

        self._table = boto3.resource("dynamodb", region_name=region).Table(table_name)

    async def _put(self, item: dict[str, Any]) -> None:
        import asyncio
        import json
        from decimal import Decimal

        # DynamoDB rejects floats; round-trip through Decimal.
        clean = json.loads(json.dumps(item), parse_float=Decimal)
        await asyncio.to_thread(self._table.put_item, Item=clean)

    async def save_investigation(
        self, investigation: InvestigationResponse, user_sub: str, tier: str = "free"
    ) -> None:
        await self._put(investigation_item(investigation, user_sub, tier))

    async def get_investigation(self, investigation_id: str) -> dict[str, Any] | None:
        import asyncio

        response = await asyncio.to_thread(
            self._table.get_item, Key={"PK": f"INV#{investigation_id}", "SK": "META"}
        )
        return response.get("Item")

    async def list_investigations(
        self, user_sub: str, limit: int = 25
    ) -> list[InvestigationSummary]:
        import asyncio

        from boto3.dynamodb.conditions import Key

        response = await asyncio.to_thread(
            lambda: self._table.query(
                IndexName="GSI1",
                KeyConditionExpression=Key("GSI1PK").eq(f"USER#{user_sub}"),
                ScanIndexForward=False,
                Limit=limit,
            )
        )
        return [
            InvestigationSummary(
                investigation_id=r["investigation_id"],
                target=r["target"],
                target_type=r["target_type"],
                created_at=r["created_at"],
                risk_score=int(r["risk_score"]),
                findings_count=int(r["findings_count"]),
            )
            for r in response.get("Items", [])
        ]

    async def record_audit(self, user_sub: str, action: str, detail: dict) -> None:
        await self._put(audit_item(user_sub, action, detail))


_repository: Repository | None = None


def get_repository() -> Repository:
    global _repository
    if _repository is None:
        settings = get_settings()
        if settings.is_local:
            log.info("repository.init", backend="in-memory")
            _repository = InMemoryRepository()
        else:
            log.info("repository.init", backend="dynamodb", table=settings.table_name)
            _repository = DynamoRepository(settings.table_name, settings.aws_region)
    return _repository
