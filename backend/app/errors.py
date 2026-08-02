"""Domain exceptions mapped to HTTP responses in main.py."""


class CloudIntelError(Exception):
    status_code = 500
    code = "internal_error"

    def __init__(self, message: str):
        self.message = message
        super().__init__(message)


class InvalidTarget(CloudIntelError):
    status_code = 400
    code = "invalid_target"


class ForbiddenTarget(CloudIntelError):
    """Target is private/reserved infrastructure — out of scope for legal OSINT."""

    status_code = 403
    code = "forbidden_target"


class NotFound(CloudIntelError):
    status_code = 404
    code = "not_found"


class QuotaExceeded(CloudIntelError):
    status_code = 429
    code = "quota_exceeded"
