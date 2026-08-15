# STRIX Findings — UniFed Nigeria Authorized Penetration Test

> Date: 2026-08-15 · Tester: Hermes (authorized security eng.) · Branch: `master` @ `1d48f6c`
> Environment: local Docker Compose (backend `:3000`, `RAILS_ENV=production`, `OIDC_JWKS_PRIVATE=ci-insecure-not-for-prod`).
> Classification per finding: **CONFIRMED / LIKELY / POTENTIAL / FALSE POSITIVE**. Severity: CRITICAL · HIGH · MEDIUM · LOW · INFORMATIONAL.

---

## CONFIRMED FINDINGS

### F-01 — Forgeable JWT signing secret (CRITICAL, DYNAMICALLY CONFIRMED)
- **Severity:** CRITICAL
- **Component:** `backend/app/contexts/identity/app/services/identity/token_service.rb:56-58` + `docker-compose.yml:55`
- **Description:** API bearer tokens are HMAC-HS256 signed with `secret = ENV.fetch("OIDC_JWKS_PRIVATE", "dev-insecure-change-me")`. The staging/local compose sets `OIDC_JWKS_PRIVATE: ${OIDC_JWKS_PRIVATE:-ci-insecure-not-for-prod}`. The running container was observed with `OIDC_JWKS_PRIVATE=ci-insecure-not-for-prod`. This is a **committed, guessable** value.
- **Dynamic PoC (executed, read-only):** Using `ruby-jwt` inside the backend container with the known secret, forged a token `{sub: <real user id>, uni: "adun", roles: ["admin"], typ: "access", iss: "https://api-staging.unifed.ng"}`.
  - `GET /api/v1/profile` **without** token → **401** (auth gate OK).
  - `GET /api/v1/profile` **with forged admin token** → **200** (authenticated response).
  - Also: 200 rapid requests each with a different spoofed `X-Forwarded-For` → **0×429** (see F-03).
- **Impact:** Anyone who knows (or guesses) the secret can forge a valid token for **any `sub` and any `roles`** → **full authentication bypass + vertical privilege escalation (any user → admin)**, impersonation, federation-trust abuse. Trivially exploitable on the current stack.
- **Root cause:** Insecure default fallback for a security-critical secret.
- **Remediation:** Fail closed — `secret` must raise if unset or equal to any known-bad value; Coolify MUST inject a ≥64-char random `OIDC_JWKS_PRIVATE`; rotate if ever used. (Hotfix applied this session — see commit.)

### F-02 — Missing `aud` validation + HS256/RS256 inconsistency (HIGH)
- **Severity:** HIGH
- **Component:** `token_service.rb` (API) vs `oidc_issuer_service.rb` (OIDC)
- **Description:** `TokenService.verify` validates `iss`/`typ`/`exp` but **not `aud`**. API uses HS256; OIDC issuer uses RS256 and advertises RS256 in discovery — the two token populations don't interoperate. Latent alg-confusion surface if the verifier is ever made alg-flexible.
- **Impact:** (a) broken SSO between OIDC- and API-issued tokens; (b) missing `aud` enables token reuse across purposes; (c) future alg-confusion risk.
- **Evidence:** `token_service.rb:7,42-50`; `oidc_issuer_service.rb`.
- **Remediation:** Pin `alg` on verify; add `verify_aud` with a configured audience; unify token subsystem on RS256 verified against JWKS (or HS256 consistently).

### F-03 — Rate limiter trusts attacker-controlled X-Forwarded-For (MEDIUM, DYNAMICALLY CONFIRMED)
- **Severity:** MEDIUM
- **Component:** `backend/lib/rate_limit_middleware.rb:20`
- **Dynamic PoC:** 200 rapid GETs to `/api/v1/catalog/courses`, each with a distinct `X-Forwarded-For` header → **200 ×199, 0 ×429**. Limiter keyed on the spoofable header, so throttling is fully bypassable.
- **Impact:** Enables credential stuffing / scraping / abuse despite `RATE_LIMIT_ENABLED=true`. (Fails open on Redis error — acceptable for availability but means no enforcement if Redis down.)
- **Remediation:** Use `request.remote_ip` with `config.action_dispatch.trusted_proxies` set to the proxy range, or read a CDN-signed client-IP header. Never parse raw XFF.

### F-04 — Federation remote key resolution unimplemented (SSRF latent) (MEDIUM)
- **Severity:** MEDIUM
- **Component:** `webfinger_service.rb:50-58` (`fetch_actor_document` stub)
- **Description:** Remote actor/public-key resolution is a no-op. SSRF is **not currently exploitable** (no outbound fetch), but remote federation is non-functional, and when implemented the resolver must validate URLs (https-only, block internal/link-local/metadata IPs).
- **Remediation:** Implement with strict URL allow-list + egress network policy; block `169.254.169.254`, `file://`, internal ranges.

### F-05 — Federation inbox: Follow auto-accepted, Delete no-op (MEDIUM)
- **Severity:** MEDIUM
- **Component:** `inbox_handler.rb:49-57`
- **Description:** `handle_follow` unconditionally returns `accepted: true` without persisting/authorizing. `handle_delete` returns the URI but performs no tombstone.
- **Impact:** Follow-spam; federated deletes silently ignored (integrity drift).
- **Remediation:** Persist follow edges; implement real tombstones; require resolvable local actor before storing.

### F-06 — No replay protection on federation inbox (MEDIUM)
- **Severity:** MEDIUM
- **Component:** `inbox_handler.rb` (whole)
- **Description:** A valid signed activity can be replayed; no nonce/`(request-target)` replay cache.
- **Remediation:** Cache processed activity `id`s (Redis SETNX + TTL); reject duplicates.

### F-07 — Hardcoded credentials in extended dev Compose (MEDIUM)
- **Severity:** MEDIUM
- **Component:** `infra/docker/docker-compose.yml:34,48`
- **Description:** opensearch/minio passwords committed in plaintext (not the staging compose, but committed and copyable).
- **Remediation:** Move to `${VAR:-...}` placeholders / Coolify secrets.

### F-09 — Notifications `read` missing ownership (BOLA, LOW) — NEW this assessment
- **Severity:** LOW
- **Component:** `notifications_controller.rb#read`
- **Description:** `NotificationService.mark_read!(id: params[:id])` with **no ownership check** → any authenticated user can mark another user's notification read by guessing its id.
- **Impact:** Read-receipt spoofing / minor integrity.
- **Remediation:** Scope by `user: current_user` (or verify `notification.user_id == current_user.id`).

### F-10 — Library loan `return` missing ownership (BOLA, MEDIUM) — NEW this assessment
- **Severity:** MEDIUM
- **Component:** `library_controller.rb#return_resource`
- **Description:** `LibraryLoan.find_by(id: params[:loan_id])` with **no ownership/role check** → any authenticated user can return/alter another user's loan. (`borrow` is correctly self-scoped via `current_student`.)
- **Impact:** Suppress/alter another user's loan state (integrity + possible abuse).
- **Remediation:** Scope loan to `student: current_student` (or `loan.student.identity_subject == current_subject`); forbid cross-user.

### F-11 — Postgres/Redis exposed on 0.0.0.0 (MEDIUM) — NEW this assessment
- **Severity:** MEDIUM
- **Component:** `docker-compose.yml:15-16, 27-28`
- **Description:** `5432:5432` and `6379:6379` are published to all interfaces. On a cloud/staging host this makes the DB/Redis directly network-reachable (Redis has no `requirepass` in this file).
- **Impact:** Network-reachable DB/Redis if the host is exposed.
- **Remediation:** Do not publish DB/Redis ports; keep them on the internal compose network only; set `requirepass` for Redis.

### F-12 — `SECRET_KEY_BASE` insecure default (MEDIUM) — NEW this assessment
- **Severity:** MEDIUM
- **Component:** `docker-compose.yml:56`
- **Description:** `SECRET_KEY_BASE: ${SECRET_KEY_BASE:-change-me-in-prod}` — same insecure-default pattern as F-01 for Rails session/CSRF secrets.
- **Remediation:** Fail closed / require explicit strong value in deployment.

### F-13 — Frontend dev-dependency CVEs (LOW)
- **Severity:** LOW
- **Component:** `frontend` npm deps
- **Description:** `npm audit` reports esbuild (moderate, dev-server only), glob (high, command-injection in CLI), minimatch (high, ReDoS), nanoid (high) — all **transitive dev dependencies** (vite/vitest/eslint), **not** in the production Next.js standalone build.
- **Impact:** Only affects local dev tooling, not the shipped app.
- **Remediation:** `npm audit fix`; bump vite/vitest/eslint-config-next; track in CI.

---

## POSITIVES (controls that held)
- **P-01** All 19 API controllers inherit `BaseController#authenticate!` → protected routes enforce auth (verified: unauth → 401).
- **P-02** `academic_records_controller#authorize_student!` and `student_ids_controller#issue` enforce correct university-scoped + role authorization.
- **P-03** Security headers strong: HSTS (`max-age=63072000; includeSubDomains; preload`), CSP (`script-src 'self'`, `frame-ancestors 'none'`), `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`.
- **P-04** Brakeman 6.1.2: **0 security warnings** (21 controllers, 50 models, Rails 8.1.3.1) — no SQLi/XSS/mass-assignment/eval/redirect.
- **P-05** No `dangerouslySetInnerHTML` / client-side authz assumptions found in frontend; authz enforced server-side.

---

## Severity distribution (this assessment)
- CRITICAL: **1** (F-01, dynamically confirmed)
- HIGH: **1** (F-02)
- MEDIUM: **7** (F-03, F-04, F-05, F-06, F-07, F-10, F-11, F-12)
- LOW: **2** (F-09, F-13)
- INFORMATIONAL: 0 (prior I-01..I-05 folded into positives/notes)

## Overall verdict
🟡 **PARTIALLY COMPLETE / ACTION REQUIRED.** One CRITICAL (auth bypass) is live-exploitable on the current stack and must be remediated before pilot. The codebase is otherwise clean at the SAST level with strong authz on academic/identity data and good security headers. Remediation plan provided separately.
