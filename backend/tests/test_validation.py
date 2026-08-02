"""The validation layer is the legal perimeter — it gets the most test coverage."""
import pytest

from app.errors import ForbiddenTarget, InvalidTarget
from app.schemas import TargetType
from app.validation import validate_domain, validate_email, validate_ip, validate_target


class TestDomain:
    @pytest.mark.parametrize(
        "raw,expected",
        [
            ("example.com", "example.com"),
            ("EXAMPLE.COM", "example.com"),
            ("https://example.com/path?q=1", "example.com"),
            ("example.com.", "example.com"),
            ("http://sub.example.co.uk:8080/x", "sub.example.co.uk"),
            ("user@example.com", "example.com"),
        ],
    )
    def test_normalises(self, raw, expected):
        assert validate_domain(raw) == expected

    @pytest.mark.parametrize("raw", ["", "no-dot", "-bad.com", "a..b.com", "x" * 300 + ".com"])
    def test_rejects_malformed(self, raw):
        with pytest.raises(InvalidTarget):
            validate_domain(raw)

    @pytest.mark.parametrize(
        "raw", ["thing.local", "db.internal", "localhost", "x.onion", "1.0.0.127.in-addr.arpa"]
    )
    def test_blocks_internal_namespaces(self, raw):
        with pytest.raises(ForbiddenTarget):
            validate_domain(raw)

    def test_ip_passed_as_domain_is_redirected(self):
        with pytest.raises(InvalidTarget, match="target_type"):
            validate_domain("8.8.8.8")


class TestIP:
    def test_accepts_public(self):
        assert validate_ip("8.8.8.8") == "8.8.8.8"
        assert validate_ip(" 1.1.1.1 ") == "1.1.1.1"

    @pytest.mark.parametrize(
        "raw", ["10.0.0.1", "192.168.1.1", "172.16.5.4", "127.0.0.1", "169.254.169.254", "::1"]
    )
    def test_blocks_private_and_metadata(self, raw):
        """169.254.169.254 is the cloud metadata endpoint — an SSRF classic."""
        with pytest.raises(ForbiddenTarget):
            validate_ip(raw)

    def test_rejects_garbage(self):
        with pytest.raises(InvalidTarget):
            validate_ip("999.1.1.1")


class TestEmail:
    def test_valid(self):
        assert validate_email("Analyst@Example.COM") == "analyst@example.com"

    @pytest.mark.parametrize("raw", ["nope", "a@b", "@example.com", "a b@example.com"])
    def test_invalid(self, raw):
        with pytest.raises(InvalidTarget):
            validate_email(raw)


def test_dispatch_by_type():
    assert validate_target("Example.com", TargetType.DOMAIN) == "example.com"
    assert validate_target("8.8.8.8", TargetType.IP) == "8.8.8.8"
