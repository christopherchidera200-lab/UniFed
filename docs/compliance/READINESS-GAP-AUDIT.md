# UniFed Nigeria — Compliance Readiness Gap Audit (DRAFT)

> **DRAFT — internal compliance audit. Status reflects repository evidence this audit (2026-08).
> No legal/compliance status invented. Where a control is technical only, it is NOT marked
> legally compliant. Classification legend: READY / PARTIAL / MISSING / BLOCKED / REQUIRES USER INPUT.**

---

## 1. Audit scope & method
Reviewed: README, ROADMAP, SAD/SDD/ADRs, FEATURE-GAP-AUDIT, STAGING-DEPLOYMENT-REPORT,
STRIX-FINDINGS / STRIX-REMEDIATION-PLAN / STRIX-TEST-MATRIX / STRIX-EXECUTIVE-SUMMARY,
prior `docs/legal/*` and `docs/business/*` sets, backend source (identity/federation/auth),
Docker/compose, Terraform, GitHub Actions, database schema. Security remediations were
**re-verified by running the regression specs** (36 security examples, 0 failures) and a
production boot check for the new SECRET_KEY_BASE guard.

## 2. Gap register

| # | Area | Finding | Status | Evidence / note |
|---|------|---------|--------|-----------------|
| G-01 | Entity | No CAC/legal-entity evidence in repo | **REQUIRES USER INPUT** | No `CAC`/`BN`/`RC` string in repo; ownership unconfirmed |
| G-02 | IP ownership | No executed contributor/IP-assignment agreements in repo | **REQUIRES USER INPUT** | Git history shows mixed identities (see entity register) |
| G-03 | LICENSE | No LICENSE file present in repository | **MISSING** | `git ls-files` returns none |
| G-04 | DPIA | No DPIA document present | **MISSING** | Created this engagement: `docs/privacy/DPIA.md` |
| G-05 | Consent ops | Consent records + withdrawal implemented; no privacy notice / DSR workflow | **PARTIAL** | `consent_records` table + `/consent` API; policy docs added |
| G-06 | Retention | No enforced retention schedule; policy docs added | **PARTIAL** | DB has no `purge` jobs for most categories |
| G-07 | DSR | No automated export/delete tooling beyond consent | **PARTIAL** | `account_deletion_requests` table exists (schema) but unverified implementation |
| G-08 | Breach response | No IR plan before this engagement | **MISSING** | Created: `docs/security/INCIDENT-AND-DATA-BREACH-RESPONSE-PLAN.md` |
| G-09 | STRIX F-01 (Critical) | Forgeable JWT secret | **CLOSED (code) / BLOCKED — EXTERNAL VALIDATION** | Fail-closed code + tests; **deployment secret rotation still pending in Coolify** |
| G-10 | STRIX F-02..F-10 | aud/alg, rate-limit IP, BOLA x2 | **CLOSED** | Verified via 36 spec examples |
| G-11 | STRIX F-04..F-06 | Federation SSRF/follow/replay | **CLOSED** | SSRF guard added + tested this engagement; follow/replay pre-existing + tested |
| G-12 | STRIX F-07 | Plaintext secrets in `infra/docker/docker-compose.yml` | **CLOSED** | Replaced with `${VAR:-}` placeholders this engagement |
| G-13 | STRIX F-11 | DB/Redis ports published | **CLOSED** | Ports removed from root `docker-compose.yml` |
| G-14 | STRIX F-12 | `SECRET_KEY_BASE` insecure default | **CLOSED** | Fail-closed initializer + boot-verified |
| G-15 | STRIX F-13 | Frontend dev-dep CVEs | **PARTIAL** | Hygiene; dev-only deps; CI `npm audit` gate recommended (not yet added) |
| G-16 | Impact framework | No baseline/KPIs before this engagement | **MISSING** | Created: `docs/impact/UNIFED-IMPACT-MEASUREMENT-FRAMEWORK.md` + pilot baseline |
| G-17 | Pen-test | No external/independent penetration test | **MISSING** | STRIX was an authorized internal/Hermes assessment; not third-party |
| G-18 | NDPA registration | No evidence of NDPC registration as data controller | **REQUIRES USER INPUT** | Legally review required |

## 3. Summary
Technical security posture is materially stronger than at the STRIX baseline (F-01..F-12
substantially closed with tests). **Legal/entity/IP, NDPA registration, and external
pen-test validation remain the dominant open gaps** and are blocked on user/institutional input.
