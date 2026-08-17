# UniFed Nigeria — Security Evidence Index (DRAFT)

> **DRAFT — index of available security evidence. Items marked NOT PERFORMED are gaps, not claims.
> No external penetration test is asserted.**

---

## Available evidence
| Evidence | Location | Status |
|----------|----------|--------|
| STRIX findings report | `docs/security/STRIX-FINDINGS.md` | Present (authorized internal assessment) |
| STRIX remediation plan | `docs/security/STRIX-REMEDIATION-PLAN.md` | Present |
| STRIX test matrix | `docs/security/STRIX-TEST-MATRIX.md` | Present |
| STRIX executive summary | `docs/security/STRIX-EXECUTIVE-SUMMARY.md` | Present |
| Remediation register (this engagement) | `docs/security/STRIX-REMEDIATION-REGISTER.md` | Present |
| Regression specs (security) | `backend/spec/contexts/federation/*`, `identity_spec`, `bola_regression_spec`, `rate_limit_spec` | **36 examples, 0 failures (verified 2026-08)** |
| Brakeman SAST | referenced in STRIX (0 warnings) | Prior report; re-run recommended in CI |
| Security headers (HSTS/CSP) | `BaseController`/secure_headers | Implemented (verified STRIX P-03) |
| Fail-closed secret guards | `token_service.rb`, `secret_key_base_guard.rb` | Implemented + boot-verified |
| Federation hardening | `signature_verifier.rb`, `inbox_handler.rb`, `processed_activity.rb` | Implemented + tested |
| Secrets hygiene | compose files | Plaintext removed (F-07/F-11/F-12) |
| CI pipelines | `.github/workflows/backend-ci.yml`, `frontend-ci.yml` | Present (extend with `npm audit` + brakeman gates) |

## Not performed (gaps)
| Evidence | Why needed | Owner |
|----------|-----------|-------|
| Independent third-party penetration test | External validation of closure | **REQUIRES EXTERNAL VALIDATION** |
| Dependency vulnerability scan (Snyk/Dependabot) | Continuous CVE monitoring | To configure |
| DAST / runtime fuzzing | Deeper coverage | To schedule |
| Centralised security logging + SIEM | Detection/response | To build |
| WAF / DDoS configuration evidence | Edge protection at scale | To configure at deploy |
| Secrets scanner (gitleaks) in CI | Prevent secret commits | To add |

## Verification commands (reproducible)
```
docker run --rm --network host -v $PWD:/repo -v unifed-bundle:/usr/local/bundle -w /repo/backend \
  ruby:3.3 bundle exec rspec spec/contexts/federation/federation_hardening_spec.rb \
  spec/contexts/federation/federation_spec.rb spec/contexts/identity/identity_spec.rb \
  spec/requests/bola_regression_spec.rb spec/requests/rate_limit_spec.rb
# => 36 examples, 0 failures
```
