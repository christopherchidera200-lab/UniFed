"""Collector registry.

A collector is a small, isolated unit that queries exactly one public source and returns
attributable Findings. Collectors never raise into the orchestrator — they return a
CollectorResult carrying their own failure state, so one dead source cannot kill an
investigation.
"""
from app.collectors.base import Collector, registry
from app.collectors.dns_collector import DNSCollector
from app.collectors.email_domain_collector import EmailDomainCollector
from app.collectors.http_collector import HTTPFingerprintCollector
from app.collectors.organization_collector import OrganizationCollector
from app.collectors.rdap_collector import RDAPCollector
from app.collectors.reverse_dns_collector import ReverseDNSCollector
from app.collectors.subdomain_collector import SubdomainCollector
from app.collectors.tls_collector import TLSCollector
from app.collectors.username_presence_collector import UsernamePresenceCollector
from app.collectors.whois_collector import WhoisCollector

registry.register(DNSCollector())
registry.register(RDAPCollector())
registry.register(ReverseDNSCollector())
registry.register(EmailDomainCollector())
registry.register(UsernamePresenceCollector())
registry.register(WhoisCollector())
registry.register(TLSCollector())
registry.register(HTTPFingerprintCollector())
registry.register(SubdomainCollector())
registry.register(OrganizationCollector())

__all__ = ["Collector", "registry"]
