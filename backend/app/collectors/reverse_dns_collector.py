"""Reverse DNS (PTR) lookup for an IP address.

Given an IPv4/IPv6 address, resolve its pointer record to discover the hostname
the owner has published. A PTR record often reveals the owning organisation, a
device role (``mail``, ``vpn``, ``www``) or a cloud provider's naming scheme —
useful corroboration for the registration data from the RDAP collector.

Uses dnspython against public resolvers, exactly like the forward DNS collector.
No third-party dependency beyond the DNS infrastructure itself.
"""
from __future__ import annotations

import dns.asyncresolver
import dns.reversename

from app.collectors.base import Collector
from app.schemas import Finding, Severity, TargetType

NAMESERVERS = ["1.1.1.1", "8.8.8.8"]


class ReverseDNSCollector(Collector):
    name = "reverse-dns"
    description = "Reverse DNS (PTR) hostname for an IP address"
    supported_types = (TargetType.IP,)
    legal_basis = (
        "PTR records are part of the public DNS, queried by anyone on the internet. "
        "No authentication or special access is required."
    )

    async def collect(self, target: str, target_type: TargetType) -> list[Finding]:
        try:
            ptr_name = dns.reversename.from_address(target)
        except Exception:
            return []

        resolver = dns.asyncresolver.Resolver(configure=False)
        resolver.nameservers = NAMESERVERS
        resolver.timeout = 3.0
        resolver.lifetime = 5.0

        try:
            answer = await resolver.resolve(ptr_name, "PTR")
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN, dns.exception.Timeout):
            return []

        hostnames = sorted(str(r.target).rstrip(".") for r in answer)
        if not hostnames:
            return []

        return [
            Finding(
                collector=self.name,
                title="Reverse DNS hostname",
                severity=Severity.INFO,
                data={"hostnames": hostnames},
                source="DNS PTR (1.1.1.1, 8.8.8.8)",
                legal_basis=self.legal_basis,
            )
        ]
