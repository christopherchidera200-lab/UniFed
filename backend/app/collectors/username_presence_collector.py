"""Username target: presence across public profiles.

A username is not an address you can probe — it is an identifier that may or may
not be claimed on various platforms. The only lawful, public signal available is
whether a profile page exists. We perform an ordinary unauthenticated GET to each
platform's public profile URL and treat HTTP 200 as "present", 404 as "absent".

Two independent platforms are checked:

  * GitHub — developer identity, repos, organisations.
  * dev.to  — publishing/writing presence.

Why exactly these two: both are developer-oriented, both serve a public profile at
a stable URL, and both return a clean 200/404 distinction on a plain GET with no
authentication and no API key. A username present on two unrelated platforms is far
more corroborated than one checked against a single site.

What we deliberately do NOT do: no authenticated requests, no scraping of private
data, no attempt to enumerate associated emails or accounts, no third-party
"data broker" / breach sources. Presence is the entire signal.
"""
from __future__ import annotations

import httpx

from app.collectors.base import Collector
from app.config import get_settings
from app.schemas import Finding, Severity, TargetType

# (platform label, profile URL template). Verified to return 200 for a real user
# and 404 for a non-existent one. Keep this list small and public-by-design.
_SOURCES: list[tuple[str, str]] = [
    ("GitHub", "https://github.com/{username}"),
    ("dev.to", "https://dev.to/{username}"),
]

_TIMEOUT = 10.0


class UsernamePresenceCollector(Collector):
    name = "username-presence"
    description = "Profile presence across GitHub and dev.to (public profiles only)"
    supported_types = (TargetType.USERNAME,)
    legal_basis = (
        "Each source is checked with a single unauthenticated GET to its public "
        "profile URL. Only the fact of a profile's existence is recorded — no "
        "private data, no authenticated calls, no associated-account enumeration."
    )

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        settings = get_settings()
        found: list[str] = []

        async with httpx.AsyncClient(
            timeout=_TIMEOUT,
            headers={"User-Agent": settings.user_agent},
            follow_redirects=True,
        ) as client:
            for label, template in _SOURCES:
                url = template.format(username=target)
                try:
                    response = await client.get(url)
                except httpx.HTTPError:
                    # A network failure for one source must not fail the others.
                    continue
                # 200 = profile exists; anything else (404, 403, 5xx) = treat as
                # not-found rather than guessing.
                if response.status_code == 200:
                    found.append(label)

        if not found:
            return [
                Finding(
                    collector=self.name,
                    title="No public profile found on checked platforms",
                    severity=Severity.INFO,
                    data={"checked": [label for label, _ in _SOURCES], "present_on": []},
                    source="GitHub, dev.to",
                    legal_basis=self.legal_basis,
                )
            ]

        corroborated = len(found) > 1
        return [
            Finding(
                collector=self.name,
                title="Username is claimed on public profiles",
                severity=Severity.LOW if corroborated else Severity.INFO,
                data={
                    "present_on": found,
                    "checked": [label for label, _ in _SOURCES],
                    "corroborated": corroborated,
                },
                source=", ".join(found),
                legal_basis=self.legal_basis,
            )
        ]
