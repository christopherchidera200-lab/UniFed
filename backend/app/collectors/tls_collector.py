"""TLS certificate inspection via a standard public handshake — no intrusion."""
from __future__ import annotations

import asyncio
import socket
import ssl
from datetime import UTC, datetime

from app.collectors.base import Collector
from app.schemas import Finding, Severity, TargetType


def _fetch_cert(host: str, port: int = 443, timeout: float = 6.0) -> dict:
    context = ssl.create_default_context()
    with socket.create_connection((host, port), timeout=timeout) as sock:
        with context.wrap_socket(sock, server_hostname=host) as tls:
            return {"cert": tls.getpeercert(), "version": tls.version(), "cipher": tls.cipher()}


class TLSCollector(Collector):
    name = "tls"
    description = "TLS certificate issuer, validity window, SANs and negotiated protocol"
    supported_types = (TargetType.DOMAIN,)
    legal_basis = (
        "A TLS handshake with a public HTTPS endpoint is the ordinary, intended use of that "
        "service. No authentication is attempted and no payload is sent."
    )

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        try:
            info = await asyncio.to_thread(_fetch_cert, target)
        except (socket.gaierror, ConnectionRefusedError, TimeoutError, OSError):
            return []
        except ssl.SSLCertVerificationError as exc:
            return [
                Finding(
                    collector=self.name,
                    title="TLS certificate failed verification",
                    severity=Severity.HIGH,
                    data={"error": str(exc)},
                    source="TLS handshake :443",
                    legal_basis=self.legal_basis,
                )
            ]

        cert = info["cert"] or {}
        subject = {k: v for entry in cert.get("subject", ()) for k, v in entry}
        issuer = {k: v for entry in cert.get("issuer", ()) for k, v in entry}
        sans = sorted({v for typ, v in cert.get("subjectAltName", ()) if typ == "DNS"})

        not_after = cert.get("notAfter")
        expires_at = None
        days_left = None
        if not_after:
            expires_at = datetime.strptime(not_after, "%b %d %H:%M:%S %Y %Z").replace(tzinfo=UTC)
            days_left = (expires_at - datetime.now(UTC)).days

        findings = [
            Finding(
                collector=self.name,
                title="TLS certificate",
                severity=Severity.INFO,
                data={
                    "subject_cn": subject.get("commonName"),
                    "issuer": issuer.get("organizationName") or issuer.get("commonName"),
                    "valid_from": cert.get("notBefore"),
                    "valid_until": not_after,
                    "days_remaining": days_left,
                    "san_count": len(sans),
                    "subject_alt_names": sans[:50],
                    "tls_version": info["version"],
                    "cipher": info["cipher"][0] if info["cipher"] else None,
                },
                source="TLS handshake :443",
                legal_basis=self.legal_basis,
            )
        ]

        if days_left is not None and days_left < 0:
            findings.append(
                Finding(
                    collector=self.name,
                    title="TLS certificate has expired",
                    severity=Severity.HIGH,
                    data={"expired_days_ago": abs(days_left)},
                    source="TLS handshake :443",
                    legal_basis=self.legal_basis,
                )
            )
        elif days_left is not None and days_left < 21:
            findings.append(
                Finding(
                    collector=self.name,
                    title=f"TLS certificate expires in {days_left} days",
                    severity=Severity.MEDIUM,
                    data={"days_remaining": days_left},
                    source="TLS handshake :443",
                    legal_basis=self.legal_basis,
                )
            )

        version = info["version"] or ""
        if version in {"TLSv1", "TLSv1.1", "SSLv3"}:
            findings.append(
                Finding(
                    collector=self.name,
                    title=f"Deprecated TLS protocol negotiated ({version})",
                    severity=Severity.HIGH,
                    data={"negotiated": version, "recommendation": "Require TLS 1.2 minimum"},
                    source="TLS handshake :443",
                    legal_basis=self.legal_basis,
                )
            )

        return findings
