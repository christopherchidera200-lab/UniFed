"""Email target: investigate the domain half of an address.

An email address is two facts stitched together: a local part and a domain. We do
not — and legally should not — probe the mailbox itself (no SMTP probing, no
account enumeration, no breach-data lookups). What is legitimately public is the
domain: its DNS posture and its registration record, both of which we already
collect for a plain domain target.

So this collector reuses the same public signals as the domain collectors, scoped
to the domain portion of the address, and explicitly omits anything that would
amount to probing the mailbox or the individual.
"""
from __future__ import annotations

import httpx

from app.collectors.base import Collector
from app.config import get_settings
from app.schemas import Finding, Severity, TargetType

_RDAP_BOOTSTRAP = "https://rdap.org/domain/"
_TIMEOUT = 10.0


class EmailDomainCollector(Collector):
    name = "email-domain"
    description = "DNS and registration posture of the email's domain (no mailbox probing)"
    supported_types = (TargetType.EMAIL,)
    legal_basis = (
        "Only the domain portion is investigated, using the same public DNS and "
        "RDAP signals as a domain investigation. The local part and mailbox are "
        "never touched — no SMTP probing, no account enumeration."
    )

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        domain = target.split("@")[-1]

        findings: list[Finding] = []
        findings.extend(await self._mx_check(domain))
        findings.extend(await self._registration(domain))
        return findings

    async def _mx_check(self, domain: str) -> list[Finding]:
        import dns.asyncresolver
        import dns.resolver

        resolver = dns.asyncresolver.Resolver(configure=False)
        resolver.nameservers = ["1.1.1.1", "8.8.8.8"]
        resolver.timeout = 3.0
        resolver.lifetime = 5.0

        try:
            answer = await resolver.resolve(domain, "MX")
            mx = sorted(str(r.exchange).rstrip(".") for r in answer)
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN, dns.exception.Timeout):
            mx = []

        if not mx:
            return [
                Finding(
                    collector=self.name,
                    title="Domain does not accept email (no MX record)",
                    severity=Severity.LOW,
                    data={"domain": domain},
                    source="DNS MX",
                    legal_basis=self.legal_basis,
                )
            ]

        return [
            Finding(
                collector=self.name,
                title="Mail is routed via published MX records",
                severity=Severity.INFO,
                data={"mx": mx},
                source="DNS MX",
                legal_basis=self.legal_basis,
            )
        ]

    async def _registration(self, domain: str) -> list[Finding]:
        settings = get_settings()
        async with httpx.AsyncClient(
            timeout=_TIMEOUT,
            headers={"User-Agent": settings.user_agent},
            follow_redirects=True,
        ) as client:
            try:
                response = await client.get(f"{_RDAP_BOOTSTRAP}{domain}")
            except httpx.HTTPError:
                return []

        if response.status_code != 200:
            return []
        data = response.json()

        registrar = _registrar(data)
        events = {e.get("eventAction"): e.get("eventDate") for e in data.get("events", [])}
        if not (registrar or events.get("expiration")):
            return []

        return [
            Finding(
                collector=self.name,
                title="Domain registration record",
                severity=Severity.INFO,
                data={
                    k: v
                    for k, v in {
                        "domain": domain,
                        "registrar": registrar,
                        "expires": events.get("expiration"),
                    }.items()
                    if v
                },
                source="RDAP",
                legal_basis=self.legal_basis,
            )
        ]


def _registrar(data: dict) -> str | None:
    for entity in data.get("entities", []):
        if "registrar" in entity.get("roles", []):
            if isinstance(entity.get("vcardArray"), list):
                for entry in entity["vcardArray"]:
                    if isinstance(entry, list):
                        for item in entry:
                            if isinstance(item, list) and len(item) >= 4 and item[0] == "fn":
                                return item[3]
            if isinstance(entity.get("name"), str):
                return entity["name"]
    return None
