"""Target validation and the abuse guardrail.

This module is the legal perimeter: anything that reaches a collector has passed through here.
"""
import ipaddress
import re

from app.errors import ForbiddenTarget, InvalidTarget
from app.schemas import TargetType

_DOMAIN_RE = re.compile(
    r"^(?=.{1,253}$)(?!-)[A-Za-z0-9-]{1,63}(?<!-)(\.(?!-)[A-Za-z0-9-]{1,63}(?<!-))+$"
)
_EMAIL_RE = re.compile(r"^[^@\s]{1,64}@([A-Za-z0-9-]{1,63}\.)+[A-Za-z]{2,}$")
_USERNAME_RE = re.compile(r"^[A-Za-z0-9._-]{2,39}$")

# Hostnames we refuse to investigate regardless of who asks.
_BLOCKED_SUFFIXES = (".local", ".internal", ".localhost", ".arpa", ".onion")
_BLOCKED_LABELS = {"localhost", "metadata", "instance-data"}


def normalize_domain(value: str) -> str:
    value = value.strip().lower().rstrip(".")
    # Tolerate users pasting URLs.
    value = re.sub(r"^[a-z]+://", "", value)
    value = value.split("/")[0].split("?")[0]
    if "@" in value:
        value = value.split("@")[-1]
    if ":" in value:
        value = value.split(":")[0]
    return value


def validate_ip(value: str) -> str:
    try:
        addr = ipaddress.ip_address(value.strip())
    except ValueError as exc:
        raise InvalidTarget(f"'{value}' is not a valid IP address") from exc
    if addr.is_private or addr.is_loopback or addr.is_link_local or addr.is_reserved:
        raise ForbiddenTarget(
            "Private, loopback, link-local and reserved addresses are out of scope. "
            "CloudIntel investigates public infrastructure only."
        )
    return str(addr)


def validate_domain(value: str) -> str:
    domain = normalize_domain(value)
    if not domain:
        raise InvalidTarget("Empty domain")
    # A bare IP passed as a domain should be routed as an IP, not rejected silently.
    try:
        ipaddress.ip_address(domain)
        raise InvalidTarget("That looks like an IP address — use target_type='ip'")
    except ValueError:
        pass
    # Blocked-namespace check runs BEFORE the format check: bare reserved labels like
    # "localhost" have no dot and would otherwise be rejected as merely malformed, hiding
    # the fact that they are deliberately out of scope.
    if domain.endswith(_BLOCKED_SUFFIXES) or domain.split(".")[0] in _BLOCKED_LABELS:
        raise ForbiddenTarget("Internal/reserved namespaces are out of scope")
    if not _DOMAIN_RE.match(domain):
        raise InvalidTarget(f"'{value}' is not a valid domain name")
    return domain


def validate_email(value: str) -> str:
    email = value.strip().lower()
    if not _EMAIL_RE.match(email):
        raise InvalidTarget(f"'{value}' is not a valid email address")
    validate_domain(email.split("@")[1])
    return email


def validate_username(value: str) -> str:
    username = value.strip()
    if not _USERNAME_RE.match(username):
        raise InvalidTarget(
            "Usernames must be 2-39 chars of letters, digits, dot, underscore or hyphen"
        )
    return username


_VALIDATORS = {
    TargetType.DOMAIN: validate_domain,
    TargetType.IP: validate_ip,
    TargetType.EMAIL: validate_email,
    TargetType.USERNAME: validate_username,
}


def validate_target(target: str, target_type: TargetType) -> str:
    return _VALIDATORS[target_type](target)
