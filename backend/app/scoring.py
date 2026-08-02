"""Risk scoring.

Deliberately transparent and rule-based rather than a black box: an analyst must be able to
justify a score in a report. Every point added carries a rationale string.
"""
from __future__ import annotations

from app.schemas import CollectorResult, RiskScore, Severity

_SEVERITY_WEIGHTS = {
    Severity.HIGH: 25,
    Severity.MEDIUM: 10,
    Severity.LOW: 3,
    Severity.INFO: 0,
}

# Diminishing returns: the 5th missing header is not 5x as bad as the first.
_MAX_PER_COLLECTOR = 40


def score_investigation(results: list[CollectorResult]) -> RiskScore:
    total = 0
    rationale: list[str] = []

    for result in results:
        subtotal = 0
        for finding in result.findings:
            weight = _SEVERITY_WEIGHTS[finding.severity]
            if weight == 0:
                continue
            subtotal += weight
            rationale.append(f"[{finding.severity.value}] {finding.title} (+{weight})")
        capped = min(subtotal, _MAX_PER_COLLECTOR)
        if capped < subtotal:
            rationale.append(
                f"[info] '{result.collector}' contribution capped at {_MAX_PER_COLLECTOR}"
            )
        total += capped

    score = min(total, 100)

    if score >= 70:
        band = "high"
    elif score >= 40:
        band = "elevated"
    elif score >= 15:
        band = "moderate"
    else:
        band = "low"

    if not rationale:
        rationale = ["No risk-bearing findings. Target shows a clean public posture."]

    return RiskScore(score=score, band=band, rationale=rationale[:40])
