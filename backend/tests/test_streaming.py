"""Streaming investigation tests.

Covers the SSE wire format, event ordering, error handling either side of the
response boundary, and the guarantee that streaming and blocking modes agree.
"""
from __future__ import annotations

import asyncio
import json

import pytest
from fastapi.testclient import TestClient

from app.collectors.base import Collector, CollectorRegistry
from app.main import app
from app.orchestrator import stream_investigation
from app.schemas import CollectorStatus, Finding, InvestigationRequest, Severity, TargetType
from app.sse import format_sse

# --------------------------------------------------------------------------- #
# Test doubles
# --------------------------------------------------------------------------- #


class _FakeCollector(Collector):
    """Collector with a controllable delay, so completion ORDER is deterministic."""

    supported_types = (TargetType.DOMAIN,)
    legal_basis = "Synthetic collector used in tests."

    def __init__(self, name: str, delay: float, findings: int = 1) -> None:
        self.name = name
        self.description = f"Fake collector {name}"
        self._delay = delay
        self._findings = findings

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        await asyncio.sleep(self._delay)
        return [
            Finding(
                collector=self.name,
                title=f"{self.name} finding {i}",
                severity=Severity.INFO,
                data={},
                source="test",
                legal_basis=self.legal_basis,
            )
            for i in range(self._findings)
        ]


class _ExplodingCollector(_FakeCollector):
    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        await asyncio.sleep(self._delay)
        raise RuntimeError("upstream source is down")


@pytest.fixture
def fake_registry(monkeypatch: pytest.MonkeyPatch):
    """Swap the global registry for one with deterministic, fast collectors."""

    def _install(*collectors: Collector) -> CollectorRegistry:
        registry = CollectorRegistry()
        for collector in collectors:
            registry.register(collector)
        monkeypatch.setattr("app.orchestrator.registry", registry)
        return registry

    return _install


def parse_sse(body: str) -> list[tuple[str, dict]]:
    """Parse an SSE body into (event, payload) pairs, ignoring comment frames."""
    events: list[tuple[str, dict]] = []
    for block in body.split("\n\n"):
        block = block.strip()
        if not block or block.startswith(":"):
            continue
        name: str | None = None
        data_lines: list[str] = []
        for line in block.split("\n"):
            if line.startswith("event: "):
                name = line.removeprefix("event: ")
            elif line.startswith("data: "):
                data_lines.append(line.removeprefix("data: "))
        if name is not None:
            events.append((name, json.loads("\n".join(data_lines))))
    return events


# --------------------------------------------------------------------------- #
# Wire format
# --------------------------------------------------------------------------- #


class TestFormatSSE:
    def test_emits_a_well_formed_frame(self):
        frame = format_sse("collector", {"collector": "dns"})
        assert frame == 'event: collector\ndata: {"collector":"dns"}\n\n'

    def test_terminates_every_frame_with_a_blank_line(self):
        # Without the trailing blank line the client never dispatches the event.
        assert format_sse("x", {}).endswith("\n\n")

    def test_folds_embedded_newlines_across_data_lines(self):
        # A raw newline inside the payload would otherwise terminate the frame early
        # and desynchronise the client parser.
        frame = format_sse("x", {"note": "line1\nline2"})
        body = frame.split("\n\n")[0]
        for line in body.split("\n")[1:]:
            assert line.startswith("data: ")
        assert "line1" in frame and "line2" in frame

    def test_serialises_non_json_native_values(self):
        from datetime import UTC, datetime

        frame = format_sse("x", {"at": datetime(2026, 8, 2, tzinfo=UTC)})
        assert "2026-08-02" in frame


# --------------------------------------------------------------------------- #
# Orchestrator generator
# --------------------------------------------------------------------------- #


class TestStreamInvestigation:
    async def test_yields_started_first_and_complete_last(self, fake_registry):
        fake_registry(_FakeCollector("alpha", 0.01))
        request = InvestigationRequest(target="example.com", target_type=TargetType.DOMAIN)

        events = [event async for event, _ in stream_investigation(request)]

        assert events[0] == "started"
        assert events[-1] == "complete"

    async def test_started_advertises_the_expected_collectors(self, fake_registry):
        fake_registry(_FakeCollector("alpha", 0.01), _FakeCollector("beta", 0.01))
        request = InvestigationRequest(target="example.com", target_type=TargetType.DOMAIN)

        gen = stream_investigation(request)
        _, payload = await anext(gen)
        await gen.aclose()

        # The UI renders one pending placeholder per name, so this must be complete.
        assert sorted(payload["collectors"]) == ["alpha", "beta"]
        assert payload["target"] == "example.com"

    async def test_emits_results_in_completion_order_not_registration_order(
        self, fake_registry
    ):
        # This is the entire point of streaming: the fast source must not wait
        # behind the slow one.
        fake_registry(
            _FakeCollector("slow", 0.20),
            _FakeCollector("fast", 0.01),
        )
        request = InvestigationRequest(target="example.com", target_type=TargetType.DOMAIN)

        order = [
            payload.collector
            async for event, payload in stream_investigation(request)
            if event == "collector"
        ]

        assert order == ["fast", "slow"]

    async def test_a_failing_collector_does_not_abort_the_stream(self, fake_registry):
        fake_registry(
            _ExplodingCollector("broken", 0.01),
            _FakeCollector("healthy", 0.02),
        )
        request = InvestigationRequest(target="example.com", target_type=TargetType.DOMAIN)

        results = {
            payload.collector: payload
            async for event, payload in stream_investigation(request)
            if event == "collector"
        }

        assert results["broken"].status is CollectorStatus.ERROR
        assert results["healthy"].status is CollectorStatus.OK

    async def test_complete_carries_the_scored_investigation(self, fake_registry):
        fake_registry(_FakeCollector("alpha", 0.01, findings=2))
        request = InvestigationRequest(target="example.com", target_type=TargetType.DOMAIN)

        final = [
            payload async for event, payload in stream_investigation(request) if event == "complete"
        ][0]

        assert final.findings_count == 2
        assert final.risk.score >= 0
        assert final.investigation_id

    async def test_investigation_id_is_stable_between_started_and_complete(
        self, fake_registry
    ):
        fake_registry(_FakeCollector("alpha", 0.01))
        request = InvestigationRequest(target="example.com", target_type=TargetType.DOMAIN)

        started_id: str | None = None
        complete_id: str | None = None
        async for event, payload in stream_investigation(request):
            if event == "started":
                started_id = payload["investigation_id"]
            elif event == "complete":
                complete_id = payload.investigation_id

        # The client keys its UI state on the id from `started`; a mismatch would
        # orphan every result it had already rendered.
        assert started_id is not None
        assert started_id == complete_id

    async def test_invalid_target_raises_before_any_event(self, fake_registry):
        fake_registry(_FakeCollector("alpha", 0.01))
        request = InvestigationRequest(target="not a domain", target_type=TargetType.DOMAIN)

        from app.errors import InvalidTarget

        with pytest.raises(InvalidTarget):
            await anext(stream_investigation(request))

    async def test_closing_early_cancels_pending_collectors(self, fake_registry):
        fake_registry(_FakeCollector("slow", 5.0), _FakeCollector("fast", 0.01))
        request = InvestigationRequest(target="example.com", target_type=TargetType.DOMAIN)

        gen = stream_investigation(request)
        await anext(gen)  # started
        await anext(gen)  # fast collector

        # Abandoning the stream must not leave the slow collector running detached.
        await asyncio.wait_for(gen.aclose(), timeout=1.0)

        slow_tasks = [t for t in asyncio.all_tasks() if t.get_name() == "slow"]

        # cancel() only REQUESTS cancellation; the task settles on a later tick.
        # Yield the loop and confirm it actually finishes rather than asserting on
        # the intermediate 'cancelling' state.
        for task in slow_tasks:
            with pytest.raises(asyncio.CancelledError):
                await asyncio.wait_for(task, timeout=1.0)

        assert all(t.done() for t in slow_tasks)
        # Crucially it did NOT run to completion — the 5s sleep was interrupted.
        assert all(t.cancelled() for t in slow_tasks)


# --------------------------------------------------------------------------- #
# HTTP endpoint
# --------------------------------------------------------------------------- #


class TestStreamEndpoint:
    def test_returns_an_event_stream_content_type(self, fake_registry):
        fake_registry(_FakeCollector("alpha", 0.01))
        with TestClient(app) as client:
            response = client.post(
                "/investigations/stream",
                json={"target": "example.com", "target_type": "domain"},
            )

        assert response.status_code == 200
        assert response.headers["content-type"].startswith("text/event-stream")

    def test_disables_proxy_buffering(self, fake_registry):
        # Without this header nginx buffers the whole response and streaming
        # silently degrades to a slow blocking request.
        fake_registry(_FakeCollector("alpha", 0.01))
        with TestClient(app) as client:
            response = client.post(
                "/investigations/stream",
                json={"target": "example.com", "target_type": "domain"},
            )

        assert response.headers["x-accel-buffering"] == "no"
        assert "no-cache" in response.headers["cache-control"]

    def test_full_event_sequence_over_http(self, fake_registry):
        fake_registry(_FakeCollector("fast", 0.01), _FakeCollector("slower", 0.05))
        with TestClient(app) as client:
            response = client.post(
                "/investigations/stream",
                json={"target": "example.com", "target_type": "domain"},
            )

        events = parse_sse(response.text)
        names = [name for name, _ in events]

        assert names[0] == "started"
        assert names[-1] == "complete"
        assert names.count("collector") == 2
        assert names.count("complete") == 1

    def test_collector_payload_preserves_the_legal_perimeter(self, fake_registry):
        fake_registry(_FakeCollector("alpha", 0.01))
        with TestClient(app) as client:
            response = client.post(
                "/investigations/stream",
                json={"target": "example.com", "target_type": "domain"},
            )

        events = parse_sse(response.text)
        collector_payload = next(p for name, p in events if name == "collector")

        # legal_basis must survive serialisation — it is the field that makes a
        # finding defensible, and the frontend renders it per finding.
        assert collector_payload["findings"][0]["legal_basis"]
        assert collector_payload["findings"][0]["source"]

    def test_invalid_target_returns_400_not_a_200_stream(self, fake_registry):
        fake_registry(_FakeCollector("alpha", 0.01))
        with TestClient(app) as client:
            response = client.post(
                "/investigations/stream",
                json={"target": "!!not-valid!!", "target_type": "domain"},
            )

        # Validation happens before the response starts, so the client gets a real
        # HTTP error rather than a 200 whose first frame says "error".
        assert response.status_code == 400
        assert response.json()["error"] == "invalid_target"

    def test_private_address_is_rejected_with_403(self, fake_registry):
        fake_registry(_FakeCollector("alpha", 0.01))
        with TestClient(app) as client:
            response = client.post(
                "/investigations/stream",
                json={"target": "10.0.0.1", "target_type": "ip"},
            )

        assert response.status_code == 403
        assert response.json()["error"] == "forbidden_target"

    def test_streamed_investigation_is_persisted(self, fake_registry):
        fake_registry(_FakeCollector("alpha", 0.01))
        with TestClient(app) as client:
            response = client.post(
                "/investigations/stream",
                json={"target": "example.com", "target_type": "domain"},
            )
            events = parse_sse(response.text)
            final = next(p for name, p in events if name == "complete")

            # A streamed run must be retrievable afterwards, exactly like a blocking one.
            fetched = client.get(f"/investigations/{final['investigation_id']}")

        assert fetched.status_code == 200
        assert fetched.json()["target"] == "example.com"

    def test_streaming_and_blocking_modes_agree(self, fake_registry):
        fake_registry(_FakeCollector("alpha", 0.01, findings=3))
        payload = {"target": "example.com", "target_type": "domain"}

        with TestClient(app) as client:
            blocking = client.post("/investigations", json=payload).json()
            streamed = next(
                p
                for name, p in parse_sse(client.post("/investigations/stream", json=payload).text)
                if name == "complete"
            )

        # Both paths share _prepare/_finalize; this pins that they cannot drift.
        assert blocking["findings_count"] == streamed["findings_count"]
        assert blocking["risk"]["score"] == streamed["risk"]["score"]
        assert blocking["target"] == streamed["target"]
        assert [r["collector"] for r in blocking["results"]] == [
            r["collector"] for r in streamed["results"]
        ]
