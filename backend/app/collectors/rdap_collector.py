"""IP and domain registration data via RDAP.

RDAP (Registration Data Access Protocol, RFC 7482/7483) is the modern,
machine-readable successor to WHOIS. It is served over HTTPS by every regional
internet registry and by the gTLD registries, requires no API key, and returns
structured JSON instead of free text that each registry formats differently.

Two target types use it:

  * IP      — query the RIR that owns the address space (network range, country,
              allocation status, abuse contact).
  * DOMAIN  — query the registry for the second-level domain (registrar,
              registration/expiry dates, name servers, domain status).

Legal posture: registration data is published by design. Querying it is the
intended use of the service, equivalent to a WHOIS lookup.
"""
from __future__ import annotations

import httpx

from app.collectors.base import Collector
from app.config import get_settings
from app.schemas import Finding, Severity, TargetType

_RDAP_BOOTSTRAP_DOMAIN = "https://rdap.org/domain/"
_RDAP_BOOTSTRAP_IP = "https://rdap.org/ip/"

# Per-collector deadline: leave headroom under the orchestrator budget so one
# slow registry cannot swallow the whole investigation.
_TIMEOUT = 10.0


class RDAPCollector(Collector):
    name = "rdap"
    description = "Registration data (network allocation, registrar, dates) via RDAP"
    supported_types = (TargetType.IP, TargetType.DOMAIN)
    legal_basis = (
        "Registration data is published by design. RDAP is the IETF-standard, "
        "machine-readable replacement for WHOIS and is served openly by every "
        "regional internet registry and gTLD operator."
    )

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        settings = get_settings()
        url = (
            f"{_RDAP_BOOTSTRAP_IP}{target}"
            if target_type is TargetType.IP
            else f"{_RDAP_BOOTSTRAP_DOMAIN}{target}"
        )

        async with httpx.AsyncClient(
            timeout=_TIMEOUT,
            headers={"User-Agent": settings.user_agent},
            follow_redirects=True,
        ) as client:
            try:
                response = await client.get(url)
            except httpx.HTTPError as exc:
                # Network-level failure. Return no findings; the runner records
                # the error state from the raised exception.
                raise RuntimeError(f"RDAP request failed: {exc}") from exc

        if response.status_code == 404:
            return []
        response.raise_for_status()
        data = response.json()

        if target_type is TargetType.IP:
            return self._ip_findings(data, target)
        return self._domain_findings(data, target)

    @staticmethod
    def _ip_findings(data: dict, target: str) -> list[Finding]:
        findings: list[Finding] = []
        name = data.get("name")
        country = (data.get("country") or "").upper()

        summary = {
            "ip": target,
            "network": name,
            "range": data.get("cidr") or data.get("startAddress"),
            "country": country or None,
            "type": data.get("type"),
        }
        findings.append(
            Finding(
                collector="rdap",
                title="IP registration record",
                severity=Severity.INFO,
                data={k: v for k, v in summary.items() if v is not None},
                source=f"RDAP ({data.get('links', [{}])[0].get('href', 'registry')})",
                legal_basis=RDAPCollector.legal_basis,
            )
        )

        # Allocation status is a real signal: a RESERVED or SPECIAL-USE block
        # returned here would be surprising and worth surfacing. Normal
        # assignments (ALLOCATED, ASSIGNED, DIRECT ALLOCATION, REASSIGNED) are not.
        net_type = (data.get("type") or "").upper()
        if net_type in {"RESERVED", "SPECIAL-USE", "UNALLOCATED", "UNSPECIFIED"}:
            findings.append(
                Finding(
                    collector="rdap",
                    title=f"Unusual allocation type: {net_type}",
                    severity=Severity.LOW,
                    data={"type": net_type},
                    source="RDAP status",
                    legal_basis=RDAPCollector.legal_basis,
                )
            )

        abuse = _first_entity_property(data, "abuse", "email")
        if abuse:
            findings.append(
                Finding(
                    collector="rdap",
                    title="Abuse contact published",
                    severity=Severity.INFO,
                    data={"abuse_email": abuse},
                    source="RDAP abuse entity",
                    legal_basis=RDAPCollector.legal_basis,
                )
            )
        return findings

    @staticmethod
    def _domain_findings(data: dict, target: str) -> list[Finding]:
        findings: list[Finding] = []
        events = {e.get("eventAction"): e.get("eventDate") for e in data.get("events", [])}
        registrar = _first_entity_property(data, "registrar", "name")

        summary = {
            "domain": target,
            "registrar": registrar,
            "registered": events.get("registration"),
            "expires": events.get("expiration"),
            "last_changed": events.get("last changed"),
            "status": [s.split(" ")[0] for s in data.get("status", [])],
            "name_servers": [
                n.get("ldhName")
                for n in data.get("nameservers", [])
                if n.get("ldhName")
            ],
        }
        findings.append(
            Finding(
                collector="rdap",
                title="Domain registration record",
                severity=Severity.INFO,
                data={k: v for k, v in summary.items() if v},
                source="RDAP",
                legal_basis=RDAPCollector.legal_basis,
            )
        )

        # Expiry is an operational risk: a lapsed domain can be re-registered by
        # a third party and pointed at attacker infrastructure.
        expiry = events.get("expiration")
        if expiry:
            from datetime import datetime

            try:
                exp = datetime.fromisoformat(expiry.replace("Z", "+00:00"))
                days = (exp - datetime.now(exp.tzinfo)).days
                if days < 30:
                    findings.append(
                        Finding(
                            collector="rdap",
                            title=f"Domain expires in {days} days",
                            severity=Severity.MEDIUM,
                            data={"expires": expiry, "days_remaining": days},
                            source="RDAP events",
                            legal_basis=RDAPCollector.legal_basis,
                        )
                    )
            except ValueError:
                pass

        # Client Transfer Prohibited is a basic anti-hijack control.
        statuses = [s.upper() for s in summary["status"]]
        has_lock = any(
            ("CLIENT TRANSFER PROHIBITED" in s or "TRANSFER PROHIBITED" in s or s == "OK")
            for s in statuses
        )
        if not has_lock:
            findings.append(
                Finding(
                    collector="rdap",
                    title="No transfer-lock status detected",
                    severity=Severity.LOW,
                    data={"statuses": summary["status"]},
                    source="RDAP status",
                    legal_basis=RDAPCollector.legal_basis,
                )
            )
        return findings


def _first_entity_property(data: dict, role: str, prop: str) -> str | None:
    """Walk the RDAP entity graph for the first entity with ``role`` and return ``prop``."""
    for entity in data.get("entities", []):
        if role in entity.get("roles", []):
            value = _deep_property(entity, prop)
            if value:
                return value
    return None


def _deep_property(node: dict, prop: str) -> str | None:
    if isinstance(node.get(prop), str):
        return node[prop]
    for vcard in node.get("vcardArray", []):
        if isinstance(vcard, list):
            for entry in vcard:
                if isinstance(entry, list) and len(entry) >= 4 and entry[0] == prop:
                    return entry[3]
    return None
