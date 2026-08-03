"""Backend contract: every target type has at least one collector.

The frontend renders a placeholder card per collector name it receives in the
`started` event. If a type had zero collectors (the Phase-0 bug, where selecting
ip/email/username returned an empty investigation), the UI would show nothing and
the user would have no signal why. This locks in that every shipped type yields
applicable collectors.
"""
from __future__ import annotations

import pytest

from app.collectors import registry
from app.schemas import InvestigationRequest, TargetType

# Minimum collectors each type MUST be able to investigate.
_EXPECTED = {
    TargetType.DOMAIN: {"dns", "rdap", "subdomains", "tls", "whois", "http"},
    TargetType.IP: {"rdap", "reverse-dns"},
    TargetType.EMAIL: {"email-domain"},
    TargetType.USERNAME: {"username-presence"},
    TargetType.ORGANIZATION: {"organization"},
}


@pytest.mark.parametrize("target_type", list(TargetType))
def test_every_type_has_collectors(target_type: TargetType):
    collectors = registry.for_type(target_type)
    assert collectors, f"{target_type.value} has no registered collectors"


@pytest.mark.parametrize("target_type,expected", list(_EXPECTED.items()))
def test_type_collectors_match_expectation(target_type: TargetType, expected: set[str]):
    names = {c.name for c in registry.for_type(target_type)}
    # Inclusion, not equality: a collector may serve additional types (e.g. rdap
    # serves domain too).
    missing = expected - names
    assert not missing, f"{target_type.value} missing collectors: {missing}"


async def test_streaming_lists_type_collectors_in_started_event():
    """The `started` event the UI depends on must name the applicable collectors."""
    from app.orchestrator import stream_investigation

    request = InvestigationRequest(target="8.8.8.8", target_type=TargetType.IP)
    events = stream_investigation(request)
    first = await events.__anext__()
    assert first[0] == "started"
    collector_names = set(first[1]["collectors"])
    assert {"rdap", "reverse-dns"}.issubset(collector_names)
