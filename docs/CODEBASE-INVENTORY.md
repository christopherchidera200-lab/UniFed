# UniFed Nigeria — Codebase Inventory (updated)

> Generated: 2026-08-15 · **HEAD:** `f923f12` · `master`, pushed.
> Working tree: clean (pre-existing `docs/audit-report-*` leftovers excluded intentionally).

## 1. Snapshot

| Item | Value |
|---|---|
| Repository | `christopherchidera200-lab/UniFed` |
| Branch / commit | `master` @ `f923f12` (fast-forward merged over remote `fba9882`) |
| Backend | Rails 8.1 modular monolith — **16 bounded contexts**, 19 API v1 controllers, 44 models |
| Frontend | Next.js — 14 page routes; Vitest (7/7) + Playwright (6/6) |
| Infra | `infra/{docker,k8s,terraform}`; `db/schema` (deterministic SQL seeds) |
| CI | `backend-ci.yml`, `frontend-ci.yml`, `terraform-plan.yml` |
| Test status | Backend RSpec **151/0**; Frontend Vitest 7/7; Playwright 6/6 |

## 2. Backend bounded contexts

`academic` · `assessment` · `calendar` · `career` · `catalog` · `examination` ·
`federation` · `identity` · `library` · `notification` · `profile` · `records` ·
`search` · `siwes` · `social` · `student_id`

## 3. Recent commit history (newest → older)

- `f923f12` — security: F-02 JWT `aud` pinning + frontend healthcheck fix
- `fba9882` — Add `.env.example` documenting `OIDC_JWKS_PRIVATE` (remote)
- `9a78e52` — ci(backend): strong test secret (fixes CI RSpec failure)
- `4c19b54` — security: remediate BOLA F-09/F-10 + rate-limit XFF F-03
- `f2e35a4` — security: authorized pentest reports + fail-closed JWT secret (F-01)
- `1d48f6c` — fix(frontend): real authenticated user data (home/create/records)
- `4502a14` — fix NODE_UNIVERSITY_ID default
- `11167ea` — fix(backend-ci): RSpec actually green (143/0)
- `5b496ca` / `ff3b2f2` — e2e shots fix / post-staging product readiness

## 4. Live Docker stack (running)

| Container | Status | Ports |
|---|---|---|
| `unifed-backend-1` | healthy | 3000 |
| `unifed-postgres-1` | healthy | 5432 (0.0.0.0) |
| `unifed-redis-1` | healthy | 6379 (0.0.0.0) |
| `unifed-frontend-1` | **Up, now healthy** (was false `unhealthy` — fixed) | 3001→3000 |

- **Live `OIDC_JWKS_PRIVATE` is now STRONG/random** (`ec4a87db…`) — the CRITICAL F-01 is **no longer exploitable** on this stack (container rebuilt/rotated after the fixes).
- Frontend healthcheck fixed: was `curl` (absent in image) → now Node `fetch` probe; GET /:3001 returns 200.

## 5. Security posture (docs/security/)

5 reports: `STRIX-PENTEST-REPORT`, `STRIX-FINDINGS`, `STRIX-REMEDIATION-PLAN`,
`STRIX-EXECUTIVE-SUMMARY`, `STRIX-TEST-MATRIX`.

**12 findings — 5 code-remediated, 7 open:**

| ID | Sev | Status |
|---|---|---|
| F-01 | CRITICAL | ✅ FIXED (fail-closed secret + live rotation) |
| F-02 | HIGH | ✅ FIXED (`aud` pinning on API tokens) |
| F-03 | MEDIUM | ✅ FIXED (rate-limit uses `remote_ip`, not raw XFF) |
| F-09 | LOW | ✅ FIXED (notifications `read` ownership-scoped) |
| F-10 | MEDIUM | ✅ FIXED (library `return` ownership-scoped) |
| F-04 | MEDIUM | OPEN — federation remote key fetch = stub (SSRF latent when built) |
| F-05 | MEDIUM | OPEN — federation Follow auto-accept / Delete no-op |
| F-06 | MEDIUM | OPEN — no federation inbox replay protection |
| F-07 | MEDIUM | OPEN — hardcoded secrets in `infra/docker/docker-compose.yml` |
| F-11 | MEDIUM | OPEN — Postgres/Redis published on 0.0.0.0 in `docker-compose.yml` |
| F--12 | MEDIUM | OPEN — `SECRET_KEY_BASE` insecure default `change-me-in-prod` |
| F-13 | LOW | OPEN — frontend dev-dep CVEs (esbuild/glob/minimatch/nanoid; not in prod build) |

**Positives:** Brakeman 0 warnings; all 19 API controllers require auth; academic/student-id authz correct; strong security headers (HSTS, CSP, XCTO, Referrer-Policy).

## 6. Changes in this update (`f923f12`)

1. **(a) Frontend healthcheck** — `docker-compose.yml`: replaced `curl` (not in image) with a Node `fetch` probe. Container now reports healthy. App was always serving (GET /:3001 → 200); the `unhealthy` flag was a false positive.
2. **(b) F-02 — JWT `aud` pinning**:
   - `backend/config/application.rb`: added `config.x.oidc_audience` (default `<issuer>/api`, overridable via `OIDC_AUDIENCE`).
   - `backend/app/contexts/identity/app/services/identity/token_service.rb`: API access + refresh tokens now embed `aud`; `verify` enforces `verify_aud` and rescues `JWT::InvalidAudienceError`. `alg` stays pinned HS256 (no alg-confusion surface).
   - `backend/spec/contexts/identity/identity_spec.rb`: 3 regression specs (correct-aud round-trips; wrong-aud rejected; missing-aud rejected).
   - Backend RSpec **148 → 151** (0 failures).
   - Security docs: F-02 marked RESOLVED in `STRIX-FINDINGS.md` + `STRIX-REMEDIATION-PLAN.md`.

## 7. Outstanding before pilot

- [ ] F-04/F-05/F-06 — federation hardening (signature verification, replay protection, Follow/Delete handling)
- [ ] F-07/F-11/F-12 — Docker/secret config (remove hardcoded secrets; stop publishing DB/Redis; fail-closed `SECRET_KEY_BASE`)
- [ ] F-13 — `npm audit fix` (dev deps only)
- [ ] Re-confirm `backend-ci` green on `f923f12` via Actions screenshot (no `gh`/token to read CI directly)

## 8. Test/CI notes

- `backend-ci.yml` sets `OIDC_JWKS_PRIVATE` to a **strong test-only** secret (fixed in `9a78e52`) so the F-01 fail-closed hardening doesn't break RSpec.
- `frontend-ci.yml` + `terraform-plan.yml` unchanged this session.
- Suite is green locally under the CI-equivalent env (strong secret + Redis); live Actions re-confirmation pending your screenshot.
