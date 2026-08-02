"""Passive subdomain enumeration from Certificate Transparency logs.

CT logs are an append-only public record every CA is required to write to (RFC 6962).
Reading them is entirely passive — we never send a single packet to the target's own
infrastructure. DNS brute-force enumeration is deliberately NOT implemented: it is noisy,
generates unsolicited traffic, and sits in a greyer legal zone.
"""
from __future__ import annotations

import httpx

from app.collectors.base import Collector
from app.config import get_settings
from app.schemas import Finding, Severity, TargetType

CRT_SH = "https://crt.sh/"

# Subdomain labels that usually indicate non-production surface worth flagging.
_SENSITIVE_LABELS = {
    "dev", "test", "staging", "stage", "uat", "qa", "sandbox", "demo",
    "admin", "internal", "intranet", "vpn", "jenkins", "gitlab", "jira",
    "grafana", "kibana", "phpmyadmin", "backup", "old", "legacy", "beta",
}


class SubdomainCollector(Collector):
    name = "subdomains"
    description = "Passive subdomain discovery from Certificate Transparency logs (crt.sh)"
    supported_types = (TargetType.DOMAIN,)
    legal_basis = (
        "Certificate Transparency logs are a mandatory public append-only record under RFC 6962. "
        "Reading them sends no traffic to the target."
    )

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        settings = get_settings()
        async with httpx.AsyncClient(
            timeout=settings.collector_timeout_seconds - 1,
            headers={"User-Agent": settings.user_agent},
        ) as client:
            response = await client.get(
                CRT_SH, params={"q": f"%.{target}", "output": "json"}
            )
            response.raise_for_status()
            try:
                entries = response.json()
            except ValueError:
                return []

        subdomains: set[str] = set()
        for entry in entries:
            for name in str(entry.get("name_value", "")).split("\n"):
                name = name.strip().lower().lstrip("*.")
                if name.endswith(f".{target}") and name != target:
                    subdomains.add(name)

        if not subdomains:
            return []

        ordered = sorted(subdomains)
        findings = [
            Finding(
                collector=self.name,
                title=f"{len(ordered)} subdomains observed in Certificate Transparency logs",
                severity=Severity.INFO,
                data={"count": len(ordered), "subdomains": ordered[:500]},
                source="crt.sh (Certificate Transparency)",
                legal_basis=self.legal_basis,
            )
        ]

        flagged = sorted(
            {
                sub
                for sub in ordered
                if any(
                    label in sub.replace(f".{target}", "").split(".")
                    for label in _SENSITIVE_LABELS
                )
            }
        )
        if flagged:
            findings.append(
                Finding(
                    collector=self.name,
                    title=f"{len(flagged)} non-production or sensitive-looking hostnames exposed",
                    severity=Severity.MEDIUM,
                    data={
                        "hosts": flagged[:100],
                        "note": "Presence in CT logs does not prove the host is reachable.",
                    },
                    source="crt.sh (Certificate Transparency)",
                    legal_basis=self.legal_basis,
                )
            )

        return findings
