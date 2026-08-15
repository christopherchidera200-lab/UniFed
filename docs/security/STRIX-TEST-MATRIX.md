# STRIX Test Matrix — UniFed Nigeria Authorized Penetration Test

> Date: 2026-08-15 · Tester: Hermes (authorized security eng.) · Branch: `master` @ `1d48f6c`
> Environment: local Docker Compose stack (backend `:3000`, frontend `:3001`, postgres `:5432`, redis `:6379`), `RAILS_ENV=production`.
> **Note on tooling:** No dedicated `strix` binary is available in this environment. The assessment was executed with a Strix-equivalent methodology — automated SAST (Brakeman), dependency CVE scanning (`npm audit`), source review, and **live dynamic testing against the authorized local stack** (curl/JWT forging/IDOR probes). Each row states the technique used so the evidence is reproducible and honestly labeled.

| # | Test case | Phase | Technique | Target | Result | Finding |
|---|-----------|-------|-----------|--------|--------|---------|
| T-01 | JWT secret default is forgeable | Recon/Dyn | Source + live token forge | `Identity::TokenService.secret` / live `/api/v1/profile` | **CONFIRMED** | F-01 CRITICAL |
| T-02 | Forge admin JWT → access protected endpoint | Dyn (PoC) | HS256 forge w/ known `ci-insecure-not-for-prod` | `POST`/GET `/api/v1/profile` | **200 with forged admin token** (unauth=401) | F-01 auth bypass + priv-esc |
| T-03 | JWT missing `aud` validation | Static | Source review `verify` | `token_service.rb` | **CONFIRMED** | F-02 HIGH |
| T-04 | HS256 vs RS256 alg inconsistency | Static | Source review | `token_service.rb` vs `oidc_issuer_service.rb` | **CONFIRMED** | F-02 HIGH |
| T-05 | Rate-limit trusts X-Forwarded-For | Dyn | 200 reqs, rotating XFF | `RateLimitMiddleware#call` | **0×429 of 200** | F-03 MEDIUM |
| T-06 | Federation remote key fetch = stub (SSRF latent) | Static | Source review | `webfinger_service.rb` | **CONFIRMED (stub)** | F-04 MEDIUM |
| T-07 | Federation inbox: Follow auto-accept, Delete no-op | Static | Source review | `inbox_handler.rb` | **CONFIRMED** | F-05 MEDIUM |
| T-08 | No replay protection on inbox | Static | Source review | `inbox_handler.rb` | **CONFIRMED** | F-06 MEDIUM |
| T-09 | Hardcoded secrets in infra compose | Static | Source review | `infra/docker/docker-compose.yml` | **CONFIRMED** | F-07 MEDIUM |
| T-10 | IDOR: notifications `read` no ownership | Static+Dyn | Source review | `NotificationsController#read` | **CONFIRMED (BOLA)** | F-09 LOW |
| T-11 | IDOR: library `return` no ownership | Static+Dyn | Source review | `LibraryController#return_resource` | **CONFIRMED (BOLA)** | F-10 MEDIUM |
| T-12 | Postgres/Redis exposed on 0.0.0.0 | Static | `docker-compose.yml` port map | `5432`, `6379` | **CONFIRMED** | F-11 MEDIUM |
| T-13 | `SECRET_KEY_BASE` insecure default | Static | `docker-compose.yml:56` | `change-me-in-prod` | **CONFIRMED** | F-12 MEDIUM |
| T-14 | Unauthenticated access to protected routes | Dyn | curl no token | `/api/v1/profile`, `/api/v1/feed`, `/api/v1/academic/...` | **401 enforced** (PASS) | Positive |
| T-15 | All 19 API controllers require auth | Static | `before_action :authenticate!` | `app/controllers/api/v1/*` | **PASS** | Positive |
| T-16 | Academic records / student-id authz | Static | Source review | `academic_records_controller.rb`, `student_ids_controller.rb` | **Correct (uni + role scoped)** | Positive (F-08 prior strength) |
| T-17 | Security headers | Dyn | curl `-D -` | `/api/v1/catalog/courses` | **HSTS+CSP+XCTO+RP present** | Positive |
| T-18 | Brakeman SAST | Auto | Brakeman 6.1.2 | backend (21 controllers, 50 models) | **0 warnings** | Positive |
| T-19 | npm dependency CVEs | Auto | `npm audit` | frontend deps | esbuild/glob/minimatch/nanoid (dev-only) | F-13 LOW |
| T-20 | SQL injection (regression of prior fix) | Dyn+Static | Brakeman + route fuzz | all params | **No SQLi (Brakeman clean)** | Positive (prior fix holds) |
| T-21 | XSS in Next.js rendering | Static | Source review + CSP | frontend | CSP `script-src 'self'`; no `dangerouslySetInnerHTML` found | Positive |
| T-22 | Federation signature verification | Static | Source review | `signature_verifier.rb` | stubbed (no real verify yet) | F-04/F-06 |

**Legend:** Dyn = dynamic/live, Static = source review, Auto = automated scanner, PoC = proof-of-concept executed.
