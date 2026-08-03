"""OrganizationCollector: builds an ownership graph from free, key-less sources.

DNS (RDAP/ASN origin) is mocked by monkeypatching the resolver; RDAP is mocked
with respx. The test asserts the graph assembles (registrant, registrar, ASN,
network owner) and degrades gracefully when a source is missing.
"""
from __future__ import annotations

import httpx
import pytest
import respx

from app.collectors.organization_collector import OrganizationCollector
from app.schemas import TargetType

pytestmark = pytest.mark.asyncio


class _FakeAnswer(list):
    def __init__(self, value: str, is_txt: bool = False):
        if is_txt:
            # dnspython TXT: str(element) returns the quoted text, e.g. '"15169 | ..."'
            super().__init__([type("TXT", (), {"__str__": lambda self: f'"{value}"'})()])
        else:
            # dnspython A: element.address is the IP string.
            super().__init__([type("A", (), {"address": value})()])


class _FakeResolver:
    def __init__(self, a_ip: str | None = None, asn_txt: str | None = None):
        self._a_ip = a_ip
        self._asn_txt = asn_txt

    async def resolve(self, name: str, rdtype: str):
        import dns.resolver

        if rdtype == "A" and self._a_ip:
            return _FakeAnswer(self._a_ip)
        if rdtype == "TXT" and self._asn_txt:
            return _FakeAnswer(self._asn_txt, is_txt=True)
        raise dns.resolver.NXDOMAIN()


async def _patch_dns(monkeypatch, a_ip=None, asn_txt=None):
    import dns.asyncresolver

    monkeypatch.setattr(
        dns.asyncresolver, "Resolver", lambda **_: _FakeResolver(a_ip=a_ip, asn_txt=asn_txt)
    )


def _domain_payload(registrar="MarkMonitor Inc.", registrant=None):
    entities = []
    if registrar:
        entities.append(
            {"roles": ["registrar"], "vcardArray": [None, [["fn", {}, "text", registrar]]]}
        )
    if registrant:
        entities.append(
            {"roles": ["registrant"], "vcardArray": [None, [["fn", {}, "text", registrant]]]}
        )
    return {"entities": entities}


def _ip_payload(net_org="Google LLC"):
    return {
        "entities": [
            {"roles": ["registrant"], "vcardArray": [None, [["fn", {}, "text", net_org]]]}
        ]
    }


async def test_org_profile_assembles_graph(monkeypatch):
    await _patch_dns(
        monkeypatch, a_ip="142.251.39.142", asn_txt="15169 | 142.251.39.0/24 | US | arin | 2012"
    )
    collector = OrganizationCollector()
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://rdap.org/domain/google.com").mock(
            return_value=httpx.Response(200, json=_domain_payload(registrant="Google LLC"))
        )
        mock.get("https://rdap.org/ip/142.251.39.142").mock(
            return_value=httpx.Response(200, json=_ip_payload("Google LLC"))
        )
        results = await collector.collect("google.com", TargetType.ORGANIZATION)

    titles = {r.title for r in results}
    assert "Organization profile" in titles
    assert "Registrant organization" in titles
    assert "Accredited registrar" in titles
    assert "Originating Autonomous System" in titles
    # Network owner skipped when it equals the registrant (no noise).
    assert "Network-owning organization" not in titles
    # The consolidated profile carries the ASN and registrant.
    profile = next(r for r in results if r.title == "Organization profile")
    assert profile.data["asn"] == "15169"
    assert profile.data["registrant"] == "Google LLC"


async def test_org_network_owner_differs_from_registrant(monkeypatch):
    await _patch_dns(monkeypatch, a_ip="1.2.3.4", asn_txt="12345 | 1.2.3.0/24 | US | arin | 2020")
    collector = OrganizationCollector()
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://rdap.org/domain/example.com").mock(
            return_value=httpx.Response(
                200, json=_domain_payload(registrar="GoDaddy", registrant=None)
            )
        )
        mock.get("https://rdap.org/ip/1.2.3.4").mock(
            return_value=httpx.Response(200, json=_ip_payload("Carrier X"))
        )
        results = await collector.collect("example.com", TargetType.ORGANIZATION)

    assert any(r.title == "Network-owning organization" for r in results)
    assert any(r.title == "Accredited registrar" for r in results)


async def test_org_missing_domain_record_is_empty_profile(monkeypatch):
    await _patch_dns(monkeypatch)  # no A record at all
    collector = OrganizationCollector()
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://rdap.org/domain/nope.invalid").mock(return_value=httpx.Response(404))
        results = await collector.collect("nope.invalid", TargetType.ORGANIZATION)

    assert len(results) == 1
    assert results[0].title == "No registration record"


async def test_org_handles_rdap_failure_gracefully(monkeypatch):
    await _patch_dns(monkeypatch, a_ip="9.9.9.9", asn_txt="13335 | 9.9.9.0/24 | US | arin | 2010")
    collector = OrganizationCollector()
    with respx.mock(assert_all_called=False) as mock:
        mock.get("https://rdap.org/domain/cloudflare.com").mock(
            side_effect=httpx.TransportError("boom")
        )
        mock.get("https://rdap.org/ip/9.9.9.9").mock(
            return_value=httpx.Response(200, json=_ip_payload("Cloudflare Inc."))
        )
        results = await collector.collect("cloudflare.com", TargetType.ORGANIZATION)

    # Still produced an ASN + network-owner finding despite the domain RDAP failure.
    assert any(r.title == "Originating Autonomous System" for r in results)
