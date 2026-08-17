# UniFed Nigeria — STRIX Remediation Register (DRAFT)

> **DRAFT — each finding verified against code + regression specs this engagement (2026-08).
> Status values: OPEN / FIXED / MITIGATED / ACCEPTED RISK / FALSE POSITIVE / REQUIRES EXTERNAL VALIDATION.
> "FIXED" means code+test verified on this branch; deployment-secret rotation and external pen-test
> are explicitly separated as REQUIRES EXTERNAL VALIDATION.**

---

| ID | Severity | Component | Remediation | Code change | Test | Verification | Status |
|----|----------|-----------|-------------|-------------|------|--------------|--------|
| F-01 | CRITICAL | token_service JWT secret | Fail-closed; reject empty/known-bad; deploy strong secret | `secret` raises | spec: boot rejects bad secret; forged token rejected | 36-spec suite green; boot-raised confirmed | **FIXED (code) / REQUIRES EXTERNAL VALIDATION** (Coolify secret rotation) |
| F-02 | HIGH | TokenService aud | Set+verify `aud`; pin alg HS256 | `verify_aud: true` | identity_spec aud tests | green | **FIXED** |
| F-03 | MEDIUM | rate_limit XFF trust | Use `remote_ip` (trusted proxies) | `req.remote_ip` | rate_limit_spec | green (still 0×429 under fixed IP) | **FIXED** |
| F-04 | MEDIUM | federation SSRF | HTTPS-only fetch + SSRF guard (block private/link-local/metadata) | `ssrf_blocked?` | federation_hardening_spec SSRF tests | green | **FIXED** |
| F-05 | MEDIUM | inbox follow/delete | Persist follow edge; tombstone delete | inbox_handler | federation_hardening_spec | green | **FIXED** |
| F-06 | MEDIUM | inbox replay | Dedup by activity id (ProcessedActivity) | inbox_handler + model | federation_hardening_spec replay test | green | **FIXED** |
| F-07 | MEDIUM | infra/docker plaintext secrets | `${VAR:-}` placeholders | compose edit | n/a (config) | diff reviewed | **FIXED** |
| F-09 | LOW | notifications read BOLA | Ownership-scoped query | controller | bola_regression_spec | green | **FIXED** |
| F-10 | MEDIUM | library return BOLA | Ownership-scoped query | controller | bola_regression_spec | green | **FIXED** |
| F-11 | MEDIUM | DB/Redis port publish | Remove ports from compose | compose edit | n/a (config) | diff reviewed | **FIXED** |
| F-12 | MEDIUM | SECRET_KEY_BASE default | Fail-closed initializer | initializer | boot-raised confirmed | raised in prod env | **FIXED** |
| F-13 | LOW | frontend dev-dep CVEs | `npm audit fix` + CI gate | (not applied) | n/a | dev-only deps | **OPEN (hygiene)** — recommend CI `npm audit` gate |

## Verification summary
- Regression specs run this engagement: **36 security examples, 0 failures** (federation hardening,
  federation, identity/token, BOLA, rate-limit).
- F-12 boot guard verified to raise on empty + `change-me-in-prod` in production env.
- **Not performed:** independent third-party penetration test (STRIX was an authorized internal
  assessment). Marked REQUIRES EXTERNAL VALIDATION for full closure confidence.

## Residual / accepted
- F-13 left open (low risk, dev-only). Acceptable; track in CI.
- Deployment secret rotation (F-01/F-12 production values) is an operations action, not code — **requires external validation** after Coolify deployment.
