"""Collector protocol, registry, and the safety wrapper every collector runs behind."""
from __future__ import annotations

import abc
import asyncio
import time

from app.config import get_settings
from app.logging_config import get_logger
from app.schemas import CollectorResult, CollectorStatus, Finding, TargetType

log = get_logger(__name__)


class Collector(abc.ABC):
    """One public source, one responsibility."""

    name: str
    description: str
    supported_types: tuple[TargetType, ...]
    legal_basis: str
    requires_api_key: bool = False

    @abc.abstractmethod
    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        """Query the source. May raise — the runner converts exceptions to ERROR results."""

    def supports(self, target_type: TargetType) -> bool:
        return target_type in self.supported_types

    async def run(self, target: str, target_type: TargetType) -> CollectorResult:
        """Never raises. Enforces the per-collector timeout budget."""
        settings = get_settings()
        started = time.perf_counter()

        if not self.supports(target_type):
            return CollectorResult(
                collector=self.name, status=CollectorStatus.SKIPPED, duration_ms=0
            )

        try:
            findings = await asyncio.wait_for(
                self.collect(target, target_type), timeout=settings.collector_timeout_seconds
            )
            status = CollectorStatus.OK if findings else CollectorStatus.EMPTY
            return CollectorResult(
                collector=self.name,
                status=status,
                duration_ms=int((time.perf_counter() - started) * 1000),
                findings=findings,
            )
        except TimeoutError:
            log.warning("collector.timeout", collector=self.name, target=target)
            return CollectorResult(
                collector=self.name,
                status=CollectorStatus.TIMEOUT,
                duration_ms=int((time.perf_counter() - started) * 1000),
                error=f"Source did not respond within {settings.collector_timeout_seconds}s",
            )
        except Exception as exc:  # noqa: BLE001 - deliberate isolation boundary
            log.warning(
                "collector.error", collector=self.name, target=target, error=str(exc)
            )
            return CollectorResult(
                collector=self.name,
                status=CollectorStatus.ERROR,
                duration_ms=int((time.perf_counter() - started) * 1000),
                error=f"{type(exc).__name__}: {exc}"[:300],
            )


class CollectorRegistry:
    def __init__(self) -> None:
        self._collectors: dict[str, Collector] = {}

    def register(self, collector: Collector) -> None:
        if collector.name in self._collectors:
            raise ValueError(f"Duplicate collector name: {collector.name}")
        self._collectors[collector.name] = collector

    def get(self, name: str) -> Collector | None:
        return self._collectors.get(name)

    def names(self) -> list[str]:
        return sorted(self._collectors)

    def for_type(self, target_type: TargetType) -> list[Collector]:
        return [c for c in self._collectors.values() if c.supports(target_type)]

    def select(self, target_type: TargetType, names: list[str] | None) -> list[Collector]:
        applicable = self.for_type(target_type)
        if names is None:
            return applicable
        wanted = set(names)
        return [c for c in applicable if c.name in wanted]


registry = CollectorRegistry()
