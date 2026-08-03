"""Public API contracts. Everything crossing the wire is defined here."""
from datetime import datetime
from enum import Enum
from typing import Any, Literal

from pydantic import BaseModel, Field


class TargetType(str, Enum):
    DOMAIN = "domain"
    IP = "ip"
    EMAIL = "email"
    USERNAME = "username"
    ORGANIZATION = "organization"


class Severity(str, Enum):
    INFO = "info"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class CollectorStatus(str, Enum):
    OK = "ok"
    EMPTY = "empty"
    TIMEOUT = "timeout"
    ERROR = "error"
    SKIPPED = "skipped"


class Finding(BaseModel):
    """One atomic, attributable fact discovered about a target."""

    collector: str
    title: str
    severity: Severity = Severity.INFO
    data: dict[str, Any] = Field(default_factory=dict)
    source: str = Field(description="Human-readable provenance, e.g. 'DNS (authoritative)'")
    legal_basis: str = Field(description="Why collecting this is lawful")


class CollectorResult(BaseModel):
    collector: str
    status: CollectorStatus
    duration_ms: int
    findings: list[Finding] = Field(default_factory=list)
    error: str | None = None
    cached: bool = False


class RiskScore(BaseModel):
    score: int = Field(ge=0, le=100, description="0 = no signal, 100 = maximum concern")
    band: Literal["low", "moderate", "elevated", "high"]
    rationale: list[str]


class InvestigationRequest(BaseModel):
    target: str = Field(min_length=1, max_length=253)
    target_type: TargetType = TargetType.DOMAIN
    collectors: list[str] | None = Field(
        default=None, description="Subset of collectors to run. None = all applicable."
    )


class InvestigationResponse(BaseModel):
    investigation_id: str
    target: str
    target_type: TargetType
    created_at: datetime
    duration_ms: int
    results: list[CollectorResult]
    risk: RiskScore
    findings_count: int


class InvestigationSummary(BaseModel):
    investigation_id: str
    target: str
    target_type: TargetType
    created_at: datetime
    risk_score: int
    findings_count: int


class HealthResponse(BaseModel):
    status: Literal["ok", "degraded"]
    environment: str
    version: str
    collectors: list[str]
