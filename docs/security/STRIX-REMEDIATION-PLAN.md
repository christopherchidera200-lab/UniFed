# STRIX Remediation Plan — UniFed Nigeria

> Date: 2026-08-15 · Author: Hermes (authorized security eng.).
> Apply in priority order. CRITICAL (F-01) and F-12 are fail-closed hotfixes (already applied this session where noted). Do **not** change live deployment values here — that is deployment config (Coolify secrets); this plan provides the code + the required secret values.

---

## P0 — CRITICAL: Fail-closed JWT secret (F-01)  [APPLIED this session]

**Risk:** Forgeable `OIDC_JWKS_PRIVATE` → auth bypass + admin priv-esc (dynamically confirmed, HTTP 200 with forged token).

**Fix (`backend/app/contexts/identity/app/services/identity/token_service.rb`):** remove the insecure default; raise if unset or known-bad.

```ruby
KNOWN_BAD = %w[dev-insecure-change-me ci-insecure-not-for-prod change-me-in-prod].freeze

def self.secret
  secret = ENV["OIDC_JWKS_PRIVATE"].to_s
  if secret.empty? || KNOWN_BAD.include?(secret)
    raise "OIDC_JWKS_PRIVATE is not configured with a strong secret (refusing to boot insecurely)"
  end
  secret
end
```

**Deployment:** Coolify MUST set `OIDC_JWKS_PRIVATE` to a random ≥64-char value; rotate if the insecure value was ever used.

**Regression test:** spec that boots with `OIDC_JWKS_PRIVATE=ci-insecure-not-for-prod` raises / rejects forged tokens; spec that a forged token with the real secret but wrong `sub` is rejected by object authz.

---

## P0 — `SECRET_KEY_BASE` fail-closed (F-12)

Same pattern as F-01. In `config/environments/production.rb` (or an initializer), raise if `SECRET_KEY_BASE` is empty or `change-me-in-prod`. Coolify sets a strong value.

---

## P1 — JWT `aud` + alg pinning (F-02)

In `TokenService.verify`:
```ruby
JWT.decode(token, secret, true,
  algorithm: ALGO,            # pin alg
  verify_iss: true, iss: issuer,
  verify_aud: true, aud: UniFed::Application.config.x.oidc_audience,
  verify_expiration: true)
```
Set `config.x.oidc_audience` (e.g. `https://api.unifed.ng`). Unify the OIDC issuer on RS256/JWKS so API- and OIDC-issued tokens interoperate; never make `alg` caller-controlled.

---

## P1 — Rate-limit client-IP trust (F-03)  [config, not code]

`RateLimitMiddleware` reads raw `HTTP_X_FORWARDED_FOR`. Replace with trusted-proxy-aware IP:
```ruby
# config/environments/production.rb
config.action_dispatch.trusted_proxies = [IPAddr.new("10.0.0.0/8"), IPAddr.new("172.16.0.0/12")] # Coolify proxy range
# middleware:
ip = request.remote_ip   # respects trusted_proxies, ignores raw XFF
```
Until then, the limiter is bypassable. Fails-open on Redis is acceptable but document it.

---

## P2 — Object-level authorization (BOLA) (F-09, F-10)

**F-09 — notifications `read`:**
```ruby
def read
  item = Notification::NotificationService.unread_for(user: current_user)
                                   .find_by(id: params[:id])
  return render json: { error: "not_found" }, status: :not_found unless item
  Notification::NotificationService.mark_read!(id: item.id)
  render json: { id: item.id, status: "read" }
end
```

**F-10 — library `return_resource`:**
```ruby
def return_resource
  student = current_student
  return render_unauthorized("no_student_link") unless student
  loan = student.library_loans.find_by(id: params[:loan_id])   # ownership-scoped
  return render json: { error: "not_found" }, status: :not_found unless loan
  returned = Library::LibraryService.return!(loan: loan)
  render json: { loan_id: returned.id, status: returned.status }
end
```
Add regression specs asserting cross-user access returns 404/403.

---

## P2 — Federation hardening (F-04, F-05, F-06)

- **F-04 (SSRF):** When implementing `fetch_actor_document`, validate URL: https-only, resolve and reject internal/link-local/metadata IPs (`169.254.169.254`), block `file://`. Add egress network policy in Coolify.
- **F-05:** Persist follow edges; implement real tombstone on Delete.
- **F-06:** Cache processed activity `id`s (Redis SETNX + TTL) and reject duplicates.

---

## P3 — Docker / secrets hygiene (F-07, F-11)

- **F-11:** Remove `5432:5432` and `6379:6379` port publishing from `docker-compose.yml` (keep services on the internal compose network). Set `requirepass` for Redis. On cloud hosts, never expose DB/Redis.
- **F-07:** Replace committed plaintext secrets in `infra/docker/docker-compose.yml` with `${VAR:-...}` placeholders; load from Coolify secrets.
- **General:** Add a boot check that refuses to start if any security secret equals a known-bad/default value.

---

## P3 — Dependency hygiene (F-13)

- `npm audit fix`; bump `vite`, `vitest`, `eslint-config-next`, `glob`, `minimatch`, `nanoid` (dev deps only; not in prod build). Track in CI so new advisories fail the build.

---

## Regression testing checklist

- [ ] Spec: forged JWT with known-bad/empty `OIDC_JWKS_PRIVATE` is rejected / boot fails.
- [ ] Spec: `verify` rejects token with wrong `aud` (F-02).
- [ ] Spec: `NotificationsController#read` returns 404 for another user's id (F-09).
- [ ] Spec: `LibraryController#return_resource` returns 404 for another user's loan (F-10).
- [ ] Spec: rate-limit returns 429 under a fixed client IP with repeated requests (F-03) — after trusted-proxy fix.
- [ ] CI: `brakeman` (already 0 warnings) + `npm audit` (F-13) gate on PRs.
- [ ] Re-run full dynamic PoC (F-01) post-fix → forged token must return 401.

---

## Implementation note

The F-01 fail-closed code change was applied and committed this session (see `STRIX-PENTEST-REPORT.md` §3). Deployment secret rotation (`OIDC_JWKS_PRIVATE`, `SECRET_KEY_BASE`) is an operations action in Coolify, not a code change, and is required before pilot.
