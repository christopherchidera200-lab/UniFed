"""Organization profile from a primary domain.

An "organization" target is anchored to its primary domain (e.g. ``google.com``).
From that single anchor we assemble an ownership graph using only free, key-less,
lawfully public sources:

  * RDAP domain record     -> registrar (the accredited registrar), and the
                              registrant organization if published.
  * DNS ``A``              -> a representative IPv4 address for the org.
  * Cymru ASN TXT          -> the originating Autonomous System (ASN, route,
                              country, RIR) — i.e. who announces the org's net.
  * RDAP IP record         -> the network-owning organization (often the same
                              legal entity as the registrant, but sometimes a
                              carrier or cloud provider — the interesting case).

Everything here is the same public data a WHOIS/RDAP lookup exposes. We never
enrich with scraped staff lists, breach corpora, or any non-public source.

Outputs one consolidated "Organization profile" finding plus discrete findings
for the registrant, registrar, ASN and network owner so each is individually
attributable and scorable.
"""
from __future__ import annotations

import dns.asyncresolver
import httpx

from app.collectors.base import Collector
from app.config import get_settings
from app.schemas import Finding, Severity, TargetType

_RDAP_DOMAIN = "https://rdap.org/domain/"
_RDAP_IP = "https://rdap.org/ip/"
_NAMESERVERS = ["1.1.1.1", "8.8.8.8"]
_TIMEOUT = 12.0

# DNS failures that mean "no answer" rather than a code defect.
_NX = (
    dns.resolver.NoAnswer,
    dns.resolver.NXDOMAIN,
    dns.exception.Timeout,
    dns.resolver.NoNameservers,
)


class OrganizationCollector(Collector):
    name = "organization"
    description = (
        "Organization profile (registrant, registrar, ASN, network owner) "
        "from a primary domain"
    )
    supported_types = (TargetType.ORGANIZATION,)
    legal_basis = (
        "Built only from registration data (RDAP) and public DNS — the same "
        "information a WHOIS lookup returns. No scraped, private or breach data is used."
    )

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        settings = get_settings()
        domain = target  # already normalized by validate_organization

        profile: dict[str, object] = {"domain": domain}
        findings: list[Finding] = []

        # 1) RDAP domain — registrant + registrar.
        registrar = None
        registrant = None
        try:
            async with httpx.AsyncClient(
                timeout=_TIMEOUT, headers={"User-Agent": settings.user_agent}, follow_redirects=True
            ) as client:
                resp = await client.get(f"{_RDAP_DOMAIN}{domain}")
            if resp.status_code == 404:
                return [
                    Finding(
                        collector=self.name,
                        title="No registration record",
                        severity=Severity.INFO,
                        data={"domain": domain},
                        source="RDAP",
                        legal_basis=self.legal_basis,
                    )
                ]
            resp.raise_for_status()
            d = resp.json()
            registrar = _entity_property(d, "registrar", "fn")
            registrant = _entity_property(d, "registrant", "fn")
        except httpx.HTTPError:
            pass

        if registrant:
            profile["registrant"] = registrant
            findings.append(
                Finding(
                    collector=self.name,
                    title="Registrant organization",
                    severity=Severity.INFO,
                    data={"registrant": registrant, "domain": domain},
                    source="RDAP registrant entity",
                    legal_basis=self.legal_basis,
                )
            )
        if registrar:
            profile["registrar"] = registrar
            findings.append(
                Finding(
                    collector=self.name,
                    title="Accredited registrar",
                    severity=Severity.INFO,
                    data={"registrar": registrar, "domain": domain},
                    source="RDAP registrar entity",
                    legal_basis=self.legal_basis,
                )
            )

        # 2) DNS A -> IP -> ASN + network owner.
        ip = await self._resolve_a(domain)
        if ip:
            profile["resolved_ip"] = ip
            asn, route, country, rir = await self._asn_for(ip)
            if asn:
                profile["asn"] = asn
                profile["asn_route"] = route
                findings.append(
                    Finding(
                        collector=self.name,
                        title="Originating Autonomous System",
                        severity=Severity.INFO,
                        data={"asn": asn, "route": route, "country": country, "rir": rir, "ip": ip},
                        source="ASN origin (Team Cymru DNS)",
                        legal_basis=self.legal_basis,
                    )
                )
            net_org = await self._network_owner(ip)
            if net_org and net_org != registrant:
                profile["network_owner"] = net_org
                findings.append(
                    Finding(
                        collector=self.name,
                        title="Network-owning organization",
                        severity=Severity.INFO,
                        data={"network_owner": net_org, "ip": ip},
                        source="RDAP IP registrant entity",
                        legal_basis=self.legal_basis,
                    )
                )

        findings.insert(
            0,
            Finding(
                collector=self.name,
                title="Organization profile",
                severity=Severity.INFO,
                data=profile,
                source="RDAP + public DNS",
                legal_basis=self.legal_basis,
            ),
        )
        return findings

    async def _resolve_a(self, domain: str) -> str | None:
        resolver = dns.asyncresolver.Resolver(configure=False)
        resolver.nameservers = _NAMESERVERS
        resolver.timeout = 4.0
        resolver.lifetime = 6.0
        try:
            answer = await resolver.resolve(domain, "A")
        except _NX:
            return None
        return str(answer[0].address) if answer else None

    async def _asn_for(self, ip: str) -> tuple[str | None, str | None, str | None, str | None]:
        resolver = dns.asyncresolver.Resolver(configure=False)
        resolver.nameservers = _NAMESERVERS
        resolver.timeout = 4.0
        resolver.lifetime = 6.0
        rev = ".".join(reversed(ip.split("."))) + ".origin.asn.cymru.com"
        try:
            answer = await resolver.resolve(rev, "TXT")
        except _NX:
            return None, None, None, None
        txt = str(answer[0]).strip('"')
        parts = [p.strip() for p in txt.split("|")]
        asn = parts[0] if len(parts) > 0 else None
        route = parts[1] if len(parts) > 1 else None
        country = parts[2].upper() if len(parts) > 2 else None
        rir = parts[3] if len(parts) > 3 else None
        return asn, route, country, rir

    async def _network_owner(self, ip: str) -> str | None:
        settings = get_settings()
        try:
            async with httpx.AsyncClient(
                timeout=_TIMEOUT, headers={"User-Agent": settings.user_agent}, follow_redirects=True
            ) as client:
                resp = await client.get(f"{_RDAP_IP}{ip}")
            if resp.status_code == 404:
                return None
            resp.raise_for_status()
            d = resp.json()
        except httpx.HTTPError:
            return None
        return _entity_property(d, "registrant", "fn") or _entity_property(
            d, "administrative", "fn"
        )


def _entity_property(data: dict, role: str, prop: str) -> str | None:
    """Return ``prop`` from the first RDAP entity carrying ``role``."""
    for entity in data.get("entities", []):
        if role in entity.get("roles", []):
            value = entity.get(prop)
            if isinstance(value, str):
                return value
            for vcard in entity.get("vcardArray", []):
                if isinstance(vcard, list):
                    for entry in vcard:
                        if isinstance(entry, list) and len(entry) >= 4 and entry[0] == prop:
                            return entry[3]
    return None
