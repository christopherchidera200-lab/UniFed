from app.schemas import CollectorResult, CollectorStatus, Finding, Severity
from app.scoring import score_investigation


def _finding(severity: Severity, title: str = "t") -> Finding:
    return Finding(
        collector="x", title=title, severity=severity, source="s", legal_basis="l"
    )


def _result(*severities: Severity, collector: str = "x") -> CollectorResult:
    return CollectorResult(
        collector=collector,
        status=CollectorStatus.OK,
        duration_ms=1,
        findings=[_finding(s, f"finding-{i}") for i, s in enumerate(severities)],
    )


def test_clean_target_scores_low():
    score = score_investigation([_result(Severity.INFO, Severity.INFO)])
    assert score.score == 0
    assert score.band == "low"
    assert "clean public posture" in score.rationale[0]


def test_severity_weighting():
    assert score_investigation([_result(Severity.HIGH)]).score == 25
    assert score_investigation([_result(Severity.MEDIUM)]).score == 10
    assert score_investigation([_result(Severity.LOW)]).score == 3


def test_bands():
    assert score_investigation([_result(Severity.LOW)]).band == "low"
    assert score_investigation([_result(Severity.MEDIUM, Severity.MEDIUM)]).band == "moderate"
    assert score_investigation([_result(Severity.HIGH, Severity.HIGH)]).band == "elevated"
    assert (
        score_investigation(
            [_result(Severity.HIGH, Severity.HIGH, collector="a"),
             _result(Severity.HIGH, Severity.HIGH, collector="b")]
        ).band
        == "high"
    )


def test_per_collector_cap_prevents_one_noisy_source_dominating():
    noisy = _result(*([Severity.HIGH] * 10))
    assert score_investigation([noisy]).score == 40


def test_score_never_exceeds_100():
    results = [_result(*([Severity.HIGH] * 5), collector=f"c{i}") for i in range(10)]
    assert score_investigation(results).score == 100


def test_rationale_is_explainable():
    result = CollectorResult(
        collector="tls",
        status=CollectorStatus.OK,
        duration_ms=1,
        findings=[_finding(Severity.HIGH, "TLS certificate has expired")],
    )
    score = score_investigation([result])
    assert any("high" in r and "expired" in r.lower() for r in score.rationale)
