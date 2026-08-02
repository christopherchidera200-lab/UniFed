"""HTTP security-header posture and passive technology fingerprinting.

Sends a single ordinary GET to the site root, exactly as a browser would. Nothing here
probes for vulnerabilities or enumerates paths.
"""
from __future__ import annotations

import re

import httpx

from app.collectors.base import Collector
from app.config import get_settings
from app.schemas import Finding, Severity, TargetType

# Signature -> (technology, category). Passive: header and body markers only.
_HEADER_SIGNATURES = {
    "x-powered-by": "runtime",
    "server": "web server",
    "x-aspnet-version": "ASP.NET",
    "x-drupal-cache": "Drupal",
    "x-generator": "generator",
    "x-shopify-stage": "Shopify",
    "x-vercel-id": "Vercel",
    "cf-ray": "Cloudflare",
    "x-amz-cf-id": "AWS CloudFront",
    "x-github-request-id": "GitHub Pages",
    "fly-request-id": "Fly.io",
}

_BODY_SIGNATURES = [
    (re.compile(r"/wp-content/|wp-json", re.I), "WordPress"),
    (re.compile(r"__NEXT_DATA__|/_next/static", re.I), "Next.js"),
    (re.compile(r"__NUXT__|/_nuxt/", re.I), "Nuxt"),
    (re.compile(r"ng-version=", re.I), "Angular"),
    (re.compile(r"data-reactroot|react(?:-dom)?\.production", re.I), "React"),
    (re.compile(r"Drupal\.settings|drupal\.js", re.I), "Drupal"),
    (re.compile(r"/sites/default/files", re.I), "Drupal"),
    (re.compile(r"Shopify\.theme", re.I), "Shopify"),
    (re.compile(r"joomla", re.I), "Joomla"),
    (re.compile(r"csrf-param.*authenticity_token", re.I), "Ruby on Rails"),
    (re.compile(r"cdn\.shopify\.com", re.I), "Shopify"),
    (re.compile(r"squarespace", re.I), "Squarespace"),
]

# Header -> (severity if missing, why it matters)
_SECURITY_HEADERS = {
    "strict-transport-security": (Severity.MEDIUM, "Allows protocol downgrade / SSL stripping"),
    "content-security-policy": (Severity.MEDIUM, "No mitigation against XSS payload execution"),
    "x-frame-options": (Severity.LOW, "Clickjacking via framing is possible"),
    "x-content-type-options": (Severity.LOW, "MIME-type sniffing is permitted"),
    "referrer-policy": (Severity.LOW, "Full URLs may leak to third parties"),
    "permissions-policy": (Severity.LOW, "Browser features are not restricted"),
}


class HTTPFingerprintCollector(Collector):
    name = "http"
    description = "HTTP security headers, redirect chain, and passive technology fingerprint"
    supported_types = (TargetType.DOMAIN,)
    legal_basis = (
        "A single unauthenticated GET to a public web root is the intended use of a public "
        "website. No path enumeration, no injection, no authentication attempts."
    )

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        settings = get_settings()
        findings: list[Finding] = []

        async with httpx.AsyncClient(
            follow_redirects=True,
            timeout=settings.collector_timeout_seconds - 1,
            headers={"User-Agent": settings.user_agent},
            verify=True,
        ) as client:
            try:
                response = await client.get(f"https://{target}/")
            except httpx.HTTPError:
                try:
                    response = await client.get(f"http://{target}/")
                    findings.append(
                        Finding(
                            collector=self.name,
                            title="Site not reachable over HTTPS",
                            severity=Severity.HIGH,
                            data={"fallback": "http"},
                            source="HTTP GET /",
                            legal_basis=self.legal_basis,
                        )
                    )
                except httpx.HTTPError:
                    return findings

        headers = {k.lower(): v for k, v in response.headers.items()}
        body = response.text[:200_000]

        chain = [str(r.url) for r in response.history] + [str(response.url)]
        findings.append(
            Finding(
                collector=self.name,
                title="HTTP response",
                severity=Severity.INFO,
                data={
                    "status_code": response.status_code,
                    "final_url": str(response.url),
                    "redirect_chain": chain if len(chain) > 1 else None,
                    "content_type": headers.get("content-type"),
                    "title": self._extract_title(body),
                },
                source="HTTP GET /",
                legal_basis=self.legal_basis,
            )
        )

        tech = self._fingerprint(headers, body)
        if tech:
            findings.append(
                Finding(
                    collector=self.name,
                    title="Technology fingerprint",
                    severity=Severity.INFO,
                    data={"technologies": tech},
                    source="HTTP response headers and body markers",
                    legal_basis=self.legal_basis,
                )
            )

        missing = [h for h in _SECURITY_HEADERS if h not in headers]
        for header in missing:
            severity, why = _SECURITY_HEADERS[header]
            findings.append(
                Finding(
                    collector=self.name,
                    title=f"Missing security header: {header}",
                    severity=severity,
                    data={"impact": why},
                    source="HTTP response headers",
                    legal_basis=self.legal_basis,
                )
            )

        # Version disclosure is a real, if minor, information leak.
        for header in ("server", "x-powered-by", "x-aspnet-version"):
            value = headers.get(header)
            if value and re.search(r"\d+\.\d+", value):
                findings.append(
                    Finding(
                        collector=self.name,
                        title=f"Version disclosure in '{header}' header",
                        severity=Severity.LOW,
                        data={"header": header, "value": value},
                        source="HTTP response headers",
                        legal_basis=self.legal_basis,
                    )
                )

        return findings

    @staticmethod
    def _extract_title(body: str) -> str | None:
        match = re.search(r"<title[^>]*>(.*?)</title>", body, re.I | re.S)
        return re.sub(r"\s+", " ", match.group(1)).strip()[:200] if match else None

    @staticmethod
    def _fingerprint(headers: dict[str, str], body: str) -> list[str]:
        found: set[str] = set()
        for header, label in _HEADER_SIGNATURES.items():
            if header in headers:
                value = headers[header]
                found.add(value if label in {"runtime", "web server", "generator"} else label)
        for pattern, tech in _BODY_SIGNATURES:
            if pattern.search(body):
                found.add(tech)
        return sorted(x for x in found if x)
