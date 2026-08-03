"""Async contract: the streaming `started` event names applicable collectors.

The UI renders one placeholder card per collector in this event. It must reflect
the actual collectors chosen for the target type.
"""
from __future__ import annotations

import pytest

from app.collectors import registry
from app.orchestrator import stream_investigation
from app.schemas import InvestigationRequest, TargetType

pytestmark = pytest.mark.asyncio


async def test_streaming_lists_type_collectors_in_started_event():
    request = InvestigationRequest(target="8.8.8.8", target_type=TargetType.IP)
    events = stream_investigation(request)
    first = await events.__anext__()
    assert first[0] == "started"
    collector_names = set(first[1]["collectors"])
    assert {"rdap", "reverse-dns"}.issubset(collector_names)


async def test_streaming_lists_email_collectors():
    request = InvestigationRequest(target="a@b.com", target_type=TargetType.EMAIL)
    events = stream_investigation(request)
    first = await events.__anext__()
    assert set(first[1]["collectors"]) == {c.name for c in registry.for_type(TargetType.EMAIL)}
