"""Collector registry.

A collector is a small, isolated unit that queries exactly one public source and returns
attributable Findings. Collectors never raise into the orchestrator — they return a
CollectorResult carrying their own failure state, so one dead source cannot kill an
investigation.
"""
from app.collectors.base import Collector, registry
from app.collectors.dns_collector import DNSCollector
from app.collectors.http_collector import HTTPFingerprintCollector
from app.collectors.subdomain_collector import SubdomainCollector
from app.collectors.tls_collector import TLSCollector
from app.collectors.whois_collector import WhoisCollector

registry.register(DNSCollector())
registry.register(WhoisCollector())
registry.register(TLSCollector())
registry.register(HTTPFingerprintCollector())
registry.register(SubdomainCollector())

__all__ = ["Collector", "registry"]
