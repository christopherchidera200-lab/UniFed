"""Collector contract tests. No network: we assert the isolation guarantees."""
import asyncio

import pytest

from app.collectors import registry
from app.collectors.base import Collector
from app.schemas import CollectorStatus, Finding, Severity, TargetType


class ExplodingCollector(Collector):
    name = "exploding"
    description = "always raises"
    supported_types = (TargetType.DOMAIN,)
    legal_basis = "test"

    async def collect(self, target, target_type):
        raise RuntimeError("upstream is on fire")


class HangingCollector(Collector):
    name = "hanging"
    description = "never returns"
    supported_types = (TargetType.DOMAIN,)
    legal_basis = "test"

    async def collect(self, target, target_type):
        await asyncio.sleep(300)
        return []


class GoodCollector(Collector):
    name = "good"
    description = "works"
    supported_types = (TargetType.DOMAIN,)
    legal_basis = "test"

    async def collect(self, target, target_type):
        return [
            Finding(
                collector=self.name,
                title="ok",
                severity=Severity.INFO,
                source="s",
                legal_basis="l",
            )
        ]


async def test_failing_collector_never_raises():
    result = await ExplodingCollector().run("example.com", TargetType.DOMAIN)
    assert result.status is CollectorStatus.ERROR
    assert "upstream is on fire" in result.error


async def test_hanging_collector_times_out(monkeypatch):
    from app.config import get_settings

    get_settings.cache_clear()
    monkeypatch.setenv("CLOUDINTEL_COLLECTOR_TIMEOUT_SECONDS", "0.1")
    result = await HangingCollector().run("example.com", TargetType.DOMAIN)
    get_settings.cache_clear()
    assert result.status is CollectorStatus.TIMEOUT


async def test_unsupported_type_is_skipped():
    result = await GoodCollector().run("someone", TargetType.USERNAME)
    assert result.status is CollectorStatus.SKIPPED


async def test_empty_findings_reported_as_empty():
    class Silent(GoodCollector):
        name = "silent"

        async def collect(self, target, target_type):
            return []

    assert (await Silent().run("example.com", TargetType.DOMAIN)).status is CollectorStatus.EMPTY


class TestRegistry:
    def test_default_collectors_registered(self):
        assert {"dns", "whois", "tls", "http", "subdomains"} <= set(registry.names())

    def test_every_collector_declares_a_legal_basis(self):
        """Compliance invariant: no source ships without a stated legal basis."""
        for name in registry.names():
            collector = registry.get(name)
            assert collector.legal_basis and len(collector.legal_basis) > 20, name

    def test_selection_filters_by_type_and_name(self):
        selected = registry.select(TargetType.DOMAIN, ["dns", "nonexistent"])
        assert [c.name for c in selected] == ["dns"]

    def test_duplicate_registration_rejected(self):
        with pytest.raises(ValueError, match="Duplicate"):
            registry.register(registry.get("dns"))
