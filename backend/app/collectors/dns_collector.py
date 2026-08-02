"""Authoritative DNS records. Zero third-party dependency, zero cost, high signal."""
from __future__ import annotations

import asyncio

import dns.asyncresolver
import dns.resolver

from app.collectors.base import Collector
from app.schemas import Finding, Severity, TargetType

RECORD_TYPES = ("A", "AAAA", "MX", "NS", "TXT", "SOA", "CNAME", "CAA")

# Public resolvers; avoids depending on whatever the Lambda VPC hands us.
NAMESERVERS = ["1.1.1.1", "8.8.8.8"]


class DNSCollector(Collector):
    name = "dns"
    description = "Authoritative DNS records (A, AAAA, MX, NS, TXT, SOA, CNAME, CAA)"
    supported_types = (TargetType.DOMAIN,)
    legal_basis = "DNS is a public, globally distributed directory designed for open query."

    def _resolver(self) -> dns.asyncresolver.Resolver:
        resolver = dns.asyncresolver.Resolver(configure=False)
        resolver.nameservers = NAMESERVERS
        resolver.timeout = 3.0
        resolver.lifetime = 5.0
        return resolver

    async def _query(self, resolver, domain: str, rtype: str) -> tuple[str, list[str]]:
        try:
            answer = await resolver.resolve(domain, rtype)
            return rtype, sorted(r.to_text().strip('"') for r in answer)
        except (
            dns.resolver.NoAnswer,
            dns.resolver.NXDOMAIN,
            dns.resolver.NoNameservers,
            dns.exception.Timeout,
        ):
            return rtype, []

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        resolver = self._resolver()
        pairs = await asyncio.gather(
            *(self._query(resolver, target, rt) for rt in RECORD_TYPES)
        )
        records = {rt: vals for rt, vals in pairs if vals}

        if not records:
            return []

        findings = [
            Finding(
                collector=self.name,
                title="DNS records",
                severity=Severity.INFO,
                data={"records": records},
                source="DNS (1.1.1.1, 8.8.8.8)",
                legal_basis=self.legal_basis,
            )
        ]

        findings.extend(self._analyze_email_security(records))
        return findings

    def _analyze_email_security(self, records: dict[str, list[str]]) -> list[Finding]:
        """SPF/DMARC posture — the highest-value derived signal in a DNS lookup."""
        out: list[Finding] = []
        txt = records.get("TXT", [])
        has_mx = bool(records.get("MX"))

        spf = next((t for t in txt if t.lower().startswith("v=spf1")), None)
        if spf is None and has_mx:
            out.append(
                Finding(
                    collector=self.name,
                    title="No SPF record on a mail-enabled domain",
                    severity=Severity.MEDIUM,
                    data={"recommendation": "Publish 'v=spf1 ... -all' to prevent spoofing"},
                    source="DNS TXT",
                    legal_basis=self.legal_basis,
                )
            )
        elif spf and ("+all" in spf or "?all" in spf):
            out.append(
                Finding(
                    collector=self.name,
                    title="Permissive SPF policy",
                    severity=Severity.HIGH,
                    data={"spf": spf, "issue": "'+all'/'?all' authorises any sender"},
                    source="DNS TXT",
                    legal_basis=self.legal_basis,
                )
            )
        elif spf and "~all" in spf:
            out.append(
                Finding(
                    collector=self.name,
                    title="SPF uses softfail (~all) rather than hardfail (-all)",
                    severity=Severity.LOW,
                    data={"spf": spf},
                    source="DNS TXT",
                    legal_basis=self.legal_basis,
                )
            )

        if not records.get("CAA"):
            out.append(
                Finding(
                    collector=self.name,
                    title="No CAA record",
                    severity=Severity.LOW,
                    data={
                        "recommendation": "CAA records restrict which CAs may issue for this domain"
                    },
                    source="DNS CAA",
                    legal_basis=self.legal_basis,
                )
            )
        return out
