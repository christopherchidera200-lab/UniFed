# STRIX scan `unifed_968e` (2026-08-15) — vuln-0001..0004 remediation log

Remediated on branch `security/strix-assessment` (commits C1–C3 below). Retest
scan pending owner decision.

## IMPORTANT — register vs actual code discrepancy
The inline Strix register's "CURRENT (vulnerable)" snippets and line numbers did
**NOT** match the code on the branch at the time of the first attempt:
- `signature_verifier.rb` was 44 lines and had **no `fetch_remote_public_key`**
  method in the stale local checkout.
- `TokenService.secret` used `ENV.fetch("OIDC_JWKS_PRIVATE", "dev-insecure-change-me")`,
  not the `KNOWN_BAD_SECRETS` version shown.

The local branch was **24 commits stale** vs the remote `security/strix-assessment`
tip. After rebasing onto the live tip, the *real* code was found to be further
along than the register assumed:
- `SignatureVerifier.fetch_remote_public_key` **does exist** on the tip and was an
  **unguarded** `Net::HTTP` call — this is the genuine vuln-0001 surface.
- The tip had already done F-04 (keyId/actor match) and F-02 (`verify_aud` +
  `KNOWN_BAD` fail-closed `secret`), but **kept HS256 with the shared
  `OIDC_JWKS_PRIVATE` secret** — so the algorithm-confusion (vuln-0004) was still
  present.

Fixes were written against the ACTUAL live tip, not the stale register snippets.

## vuln-0001 + vuln-0002 (SSRF, CRITICAL) — FIXED
- New `backend/app/contexts/federation/app/services/federation/ssrf_guard.rb`:
  `Federation::SsrfGuard.blocked_host?` resolves the host and refuses loopback,
  RFC1918, link-local / cloud-metadata (169.254.0.0/16, 169.254.169.254/32),
  and IPv6 loopback/link-local/unique-local. Fail-closed on DNS failure / blank.
- Guard the two real network boundaries:
  - `SignatureVerifier.fetch_remote_public_key` (live inbox path) — was an
    unguarded `Net::HTTP` call to an attacker-supplied `actor_uri`.
  - `WebfingerService.fetch_actor_document` — now the real HTTPS fetch,
    https-only (Net::HTTP does not follow redirects by default).
- Shared guard required once in `app/contexts/federation/lib/federation.rb`
  (no duplicated `blocked_host?`).
- Regression: `ssrf_guard_spec.rb`, `webfinger_ssrf_spec.rb` — assert
  169.254.169.254, 127.0.0.1, 10/8, 172.16/12, 192.168/16, ::1 are rejected
  **before any HTTP call** (`Net::HTTP` never instantiated for blocked hosts),
  plus a hermetic success path.

## vuln-0004 (OIDC algorithm confusion, HIGH) — FIXED
- Chose **Option B** (dedicated secret) over Option A (full RS256 migration):
  the `secret` is consumed in 5 places (`key_service` ×2, `mfa_service` ×2,
  `auth_controller` ×3), so a dedicated `TOKEN_SERVICE_SECRET` closes the
  confusion with near-zero blast radius while keeping the already-pinned
  `algorithm: ALGO` allow-listing.
- `TokenService.secret` now reads `TOKEN_SERVICE_SECRET` only; fail-closed if
  empty/known-bad. It never touches `OIDC_JWKS_PRIVATE` (the RS256 signing key),
  so the published public key can no longer double as the HMAC secret.
- `sub` stringified (`user.id.to_s`) for OIDC/JWT correctness.
- Deployment: `.env.staging.example` now documents `TOKEN_SERVICE_SECRET` with
  explicit guidance that it MUST differ from `OIDC_JWKS_PRIVATE`.
- Regression: `token_service_algo_spec.rb` — an HS256 token signed with the
  RS256 public key is rejected; a wrong-aud token is rejected; the HS256
  round-trip + tamper rejection still pass.

## vuln-0003 (signature header coverage, HIGH) — FIXED
- `SignatureVerifier` now enforces
  `REQUIRED_HEADERS = %w[(request-target) host date]`; rejects when any required
  header is missing from the signed set, or when the `headers` parameter is
  absent entirely. Adds a ±5-minute `date` skew check (`Time.httpdate` parse;
  reject blank/malformed/stale/future).
- Regression: `signature_verifier_spec.rb` — host-stripped, date-stripped,
  no-headers, and out-of-window signatures all fail; a fully-covered valid
  signature still passes. Pre-existing `federation_spec.rb` and
  `federation_hardening_spec.rb` updated to valid HTTP-date values (they used
  the literal `"now"`).

## Pre-existing FactoryBot duplicate bug — NOT REPRODUCIBLE
The handoff claimed a `FactoryBot::DuplicateDefinitionError: Sequence already
registered: uni_slug` blocker. Verified empirically on the live tip: only one
flat `spec/factories.rb` exists (explicitly required once in `rails_helper.rb`);
RSpec loads and the federation + identity suite runs 73 examples, 0 failures.
No fix committed (would be spurious). Flagged per instructions.

## Post-commit regression — vuln-0004 first attempt BROKE CI (logged honestly)
The first vuln-0004 fix required `TOKEN_SERVICE_SECRET` with no fallback, but CI
only sets `OIDC_JWKS_PRIVATE` (backend-ci.yml:24). Token issuance then raised,
so every auth-gated request spec failed the `test` job:
- `spec/requests/lms_spec.rb` and `spec/requests/research_spec.rb` → 401
  (`Bearer ` with no token) → CI `test` job RED. (The `security` job stayed
  green because it never boots Rails / issues tokens.)
- Root cause: the fix changed the secret source without carrying the env into
  CI, and the verification reported at the time was federation+identity ONLY
  (73/0 + 35 security specs) — it did NOT include the request specs that broke.
  That scoping gap is exactly why the failure reached CI instead of being
  caught locally.

Correction (commits 3bcd17d then 4b837c4):
1. `TokenService.secret` uses `TOKEN_SERVICE_SECRET` when present, else a
   NON-production fallback to `OIDC_JWKS_PRIVATE` (dev/test/CI keep booting).
   CI now ALSO sets `TOKEN_SERVICE_SECRET` as its own DISTINCT value
   (backend-ci.yml), so CI exercises the real two-secret path, not the fallback.
2. The production fail-closed check was strengthened from "is it set?" to
   "is it set AND distinct from OIDC_JWKS_PRIVATE?". A production deploy that
   copy-pastes the RSA key into `TOKEN_SERVICE_SECRET` now fails closed — the
   original vuln was same-value confusion, not merely absence.
3. `token_service_prod_spec.rb` expanded to assert BOTH the unset case AND the
   same-value case raise in production, and the distinct-value case passes.

## Second regression — working tree was reverted, source fixes were lost (logged honestly)
A diagnostic `git checkout 24fa822 -- backend/...` (run to compare the pre-fix
base) mutated the working tree back to the VULNERABLE source, and that reverted
source was subsequently committed. Result: the four source-file fixes
(token_service.rb, federation.rb, signature_verifier.rb, webfinger_service.rb)
were byte-identical to the pre-fix base `24fa822`, while the *specs* (which
expect the patched behaviour) remained. The branch was internally inconsistent.

Evidence: CI `test` job RED with
`NameError: uninitialized constant Federation::SsrfGuard` at
`ssrf_guard_spec.rb:3` — the `require_relative ".../ssrf_guard"` line had been
lost from `federation.rb`, and `git diff 24fa822 HEAD --stat` showed none of
the four source files changed (only new `*_spec.rb`, env, CI yml, docs).

Correction (commits e4a51a3 then e28c471):
1. Re-applied ALL four source fixes to match the surviving specs:
   - `federation.rb`: restored `require_relative ".../ssrf_guard"` (fixes the
     CI NameError).
   - `webfinger_service.rb`: real guarded https fetch (vuln-0002).
   - `signature_verifier.rb`: guarded `fetch_remote_public_key` (vuln-0001) +
     REQUIRED_HEADERS (host/date) + ±5m date skew (vuln-0003).
   - `token_service.rb`: dedicated `TOKEN_SERVICE_SECRET`; production fails
     closed when unset OR equal to `OIDC_JWKS_PRIVATE` (same-value confusion,
     vuln-0004); `production?` derived from `RAILS_ENV`/`RACK_ENV` (deterministic
     — the earlier `Rails.env` stub did not propagate into the method).
2. Bug caught by the FULL suite: vuln-0003 passed the parsed header ARRAY to
   `build_signed_string`, whose `headers.to_s.split` on an Array yields
   `"#<Array:...>"` (not a joined string) → every signature verify returned
   false. Fixed by passing the original `params["headers"]` string. (Confirmed
   by the full run dropping from 4 failures back to 1.)

Lesson reinforced: never `git checkout <base> -- <paths>` into a live working
tree during an active remediation; use a throwaway worktree/container instead.
And the FULL suite (not targeted subsets) is the only honest "done" signal.

## Verification (final, this turn)
- FULL SUITE: `bundle exec rspec` (no path filter) on Docker Ruby 3.3 + Postgres
  `unifed_test`, both secrets DISTINCT (matching CI): **233 examples, 1 failure**.
- The one failure is `spec/requests/rate_limit_spec.rb:40` (RateLimitMiddleware
  XFF/limit counting) — PRE-EXISTING (fails in isolation and on base `24fa822`,
  no STRIX code touches rate-limiting), OUT OF SCOPE. Every STRIX finding and its
  regression spec is green.
- Ad-hoc targeted re-checks this turn: `ssrf_guard_spec` (4/0),
  `webfinger_ssrf_spec` (6/0), `signature_verifier_spec` (6/0),
  `token_service_algo_spec` (4/0), `token_service_prod_spec` (3/0, including the
  same-value-confusion case), `lms_spec`+`research_spec` (13/0 with only
  `OIDC_JWKS_PRIVATE` set).

## Commits (on security/strix-assessment, branch-only — not merged to master)
- C1 `fix(federation): add SSRF protection to remote actor fetch (vuln-0001/vuln-0002)`
- C2 `fix(identity): close JWT algorithm-confusion via dedicated token secret (vuln-0004)`
- C3 `fix(federation): enforce required signed-header set + date window (vuln-0003)`
