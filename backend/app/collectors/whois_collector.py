"""Registration metadata via WHOIS/RDAP. Domain age is a strong phishing signal."""
from __future__ import annotations

import asyncio
from datetime import UTC, datetime

import whois

from app.collectors.base import Collector
from app.schemas import Finding, Severity, TargetType


def _first(value):
    if isinstance(value, list):
        return value[0] if value else None
    return value


def _iso(value) -> str | None:
    value = _first(value)
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=UTC)
        return value.isoformat()
    return str(value) if value else None


class WhoisCollector(Collector):
    name = "whois"
    description = "Domain registration record: registrar, dates, nameservers, status"
    supported_types = (TargetType.DOMAIN,)
    legal_basis = (
        "WHOIS/RDAP is published by registries under ICANN policy for public accountability."
    )

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        # python-whois is blocking (socket + subprocess); keep the event loop free.
        record = await asyncio.to_thread(whois.whois, target)

        if not record or not record.get("domain_name"):
            return []

        created = _first(record.get("creation_date"))
        data = {
            "registrar": _first(record.get("registrar")),
            "created": _iso(record.get("creation_date")),
            "expires": _iso(record.get("expiration_date")),
            "updated": _iso(record.get("updated_date")),
            "status": record.get("status"),
            "name_servers": sorted({n.lower() for n in (record.get("name_servers") or [])}),
            "registrant_country": _first(record.get("country")),
            "emails": record.get("emails"),
        }

        findings = [
            Finding(
                collector=self.name,
                title="WHOIS registration record",
                severity=Severity.INFO,
                data={k: v for k, v in data.items() if v},
                source="WHOIS / RDAP",
                legal_basis=self.legal_basis,
            )
        ]

        if isinstance(created, datetime):
            if created.tzinfo is None:
                created = created.replace(tzinfo=UTC)
            age_days = (datetime.now(UTC) - created).days
            if age_days < 30:
                findings.append(
                    Finding(
                        collector=self.name,
                        title=f"Domain registered {age_days} days ago",
                        severity=Severity.HIGH,
                        data={"age_days": age_days, "created": created.isoformat()},
                        source="WHOIS creation date",
                        legal_basis=self.legal_basis,
                    )
                )
            elif age_days < 365:
                findings.append(
                    Finding(
                        collector=self.name,
                        title=f"Domain is less than a year old ({age_days} days)",
                        severity=Severity.LOW,
                        data={"age_days": age_days},
                        source="WHOIS creation date",
                        legal_basis=self.legal_basis,
                    )
                )

        expires = _first(record.get("expiration_date"))
        if isinstance(expires, datetime):
            if expires.tzinfo is None:
                expires = expires.replace(tzinfo=UTC)
            days_left = (expires - datetime.now(UTC)).days
            if days_left < 0:
                findings.append(
                    Finding(
                        collector=self.name,
                        title="Domain registration has expired",
                        severity=Severity.HIGH,
                        data={"expired_days_ago": abs(days_left)},
                        source="WHOIS expiry date",
                        legal_basis=self.legal_basis,
                    )
                )
            elif days_left < 30:
                findings.append(
                    Finding(
                        collector=self.name,
                        title=f"Domain expires in {days_left} days",
                        severity=Severity.MEDIUM,
                        data={"days_remaining": days_left},
                        source="WHOIS expiry date",
                        legal_basis=self.legal_basis,
                    )
                )

        return findings
