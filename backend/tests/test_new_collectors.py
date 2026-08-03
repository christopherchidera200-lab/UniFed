"""Collector tests for the non-domain target types.

Network sources are mocked with respx so the suite is deterministic and offline.
Each test asserts: the right collectors fire for the type, findings carry a legal
basis, and a source failure degrades gracefully rather than raising.
"""
from __future__ import annotations

from datetime import UTC

import httpx
import pytest
import respx

from app.collectors.email_domain_collector import EmailDomainCollector
from app.collectors.rdap_collector import RDAPCollector
from app.collectors.reverse_dns_collector import ReverseDNSCollector
from app.collectors.username_presence_collector import UsernamePresenceCollector
from app.schemas import TargetType

pytestmark = pytest.mark.asyncio


# --- RDAP (IP + domain) ------------------------------------------------------


async def test_rdap_handles_ip():
    collector = RDAPCollector()
    payload = {
        "name": "8.8.8.0/24",
        "country": "us",
        "type": "DIRECT ALLOCATION",
        "entities": [
            {"roles": ["abuse"], "vcardArray": [None, [["email", {}, "text", "abuse@example.net"]]]}
        ],
    }
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://rdap.org/ip/8.8.8.8").mock(
            return_value=httpx.Response(200, json=payload)
        )
        results = await collector.collect("8.8.8.8", TargetType.IP)

    assert len(results) == 2
    assert results[0].title == "IP registration record"
    assert results[0].legal_basis
    # DIRECT ALLOCATION is normal; no "unusual allocation type" finding.
    assert not any("Unusual allocation" in r.title for r in results)


async def test_rdap_flags_reserved_allocation():
    collector = RDAPCollector()
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://rdap.org/ip/10.0.0.1").mock(
            return_value=httpx.Response(200, json={"name": "10.in-addr.arpa", "type": "RESERVED"})
        )
        results = await collector.collect("10.0.0.1", TargetType.IP)
    assert any("Unusual allocation type: RESERVED" in r.title for r in results)


async def test_rdap_handles_domain_expiry():
    from datetime import datetime, timedelta

    collector = RDAPCollector()
    soon = (datetime.now(UTC) + timedelta(days=10)).isoformat()
    payload = {
        "events": [{"eventAction": "expiration", "eventDate": soon}],
        "entities": [
            {
                "roles": ["registrar"],
                "vcardArray": [None, [["fn", {}, "text", "Example Registrar"]]],
            }
        ],
    }
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://rdap.org/domain/example.com").mock(
            return_value=httpx.Response(200, json=payload)
        )
        results = await collector.collect("example.com", TargetType.DOMAIN)

    assert any("expires in" in r.title for r in results)


async def test_rdap_404_returns_empty():
    collector = RDAPCollector()
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://rdap.org/domain/nope.invalid").mock(
            return_value=httpx.Response(404)
        )
        assert await collector.collect("nope.invalid", TargetType.DOMAIN) == []


# --- Reverse DNS -------------------------------------------------------------


async def test_reverse_dns_finds_hostname(monkeypatch):
    collector = ReverseDNSCollector()

    class _Answer:
        target = "dns.google."

    class _Resolver:
        async def resolve(self, name, rdtype):
            return [_Answer()]

    monkeypatch.setattr(
        "app.collectors.reverse_dns_collector.dns.asyncresolver.Resolver",
        lambda **_: _Resolver(),
    )

    results = await collector.collect("8.8.8.8", TargetType.IP)
    assert results and results[0].title == "Reverse DNS hostname"
    assert results[0].data["hostnames"] == ["dns.google"]


async def test_reverse_dns_missing_is_empty(monkeypatch):
    import dns.resolver

    collector = ReverseDNSCollector()

    class _Resolver:
        async def resolve(self, name, rdtype):
            raise dns.resolver.NXDOMAIN()

    monkeypatch.setattr(
        "app.collectors.reverse_dns_collector.dns.asyncresolver.Resolver",
        lambda **_: _Resolver(),
    )
    assert await collector.collect("198.51.100.1", TargetType.IP) == []


# --- Email domain ------------------------------------------------------------


async def test_email_domain_investigates_domain_half(monkeypatch):
    import dns.asyncresolver

    class _Answer:
        exchange = "aspmx.l.google.com."

    class _Resolver:
        async def resolve(self, name, rdtype):
            return [_Answer()]

    monkeypatch.setattr(dns.asyncresolver, "Resolver", lambda **_: _Resolver())

    collector = EmailDomainCollector()
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://rdap.org/domain/example.com").mock(
            return_value=httpx.Response(
                200,
                json={
                    "entities": [
                        {
                            "roles": ["registrar"],
                            "vcardArray": [None, [["fn", {}, "text", "Reg"]]],
                        }
                    ]
                },
            )
        )
        results = await collector.collect("alice@example.com", TargetType.EMAIL)

    assert any(r.title == "Mail is routed via published MX records" for r in results)
    assert any(r.title == "Domain registration record" for r in results)
    # The local part is never probed.
    assert not any("alice" in str(r.data) for r in results)


# --- Username presence -------------------------------------------------------


async def test_username_present_on_two_sources_is_corroborated():
    collector = UsernamePresenceCollector()
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://github.com/octocat").mock(return_value=httpx.Response(200))
        mock.get("https://dev.to/octocat").mock(return_value=httpx.Response(200))
        results = await collector.collect("octocat", TargetType.USERNAME)

    assert results[0].data["present_on"] == ["GitHub", "dev.to"]
    assert results[0].data["corroborated"] is True
    assert results[0].severity.value == "low"


async def test_username_absent_on_all():
    collector = UsernamePresenceCollector()
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://github.com/nobody_xyz").mock(return_value=httpx.Response(404))
        mock.get("https://dev.to/nobody_xyz").mock(return_value=httpx.Response(404))
        results = await collector.collect("nobody_xyz", TargetType.USERNAME)

    assert results[0].data["present_on"] == []
    assert results[0].title.startswith("No public profile")


async def test_username_one_source_down_does_not_fail_others():
    collector = UsernamePresenceCollector()
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://github.com/ada").mock(return_value=httpx.Response(200))
        mock.get("https://dev.to/ada").mock(
            side_effect=httpx.TransportError("boom")
        )
        results = await collector.collect("ada", TargetType.USERNAME)

    # GitHub succeeded, dev.to failure was swallowed.
    assert results[0].data["present_on"] == ["GitHub"]
