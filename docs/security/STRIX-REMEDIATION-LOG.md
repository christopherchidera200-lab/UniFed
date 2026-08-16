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

## Verification
- RSpec on Docker Ruby 3.3 + Postgres `unifed_test`:
  `spec/contexts/federation spec/contexts/identity` → **73 examples, 0 failures**.
- Note: the full-suite run was not completed in CI-style here (Docker boot +
  ~153 specs exceeded the local run window); the four findings and all touched
  code live in the federation + identity contexts, which are verified green.
  Recommend confirming the full suite in CI after push.
- Pre-fix control: the new regression specs fail against the old code and pass
  against the patched code (SSRF ranges, HS256/RS256 rejection, stripped-header
  rejection).

## Commits (on security/strix-assessment, branch-only — not merged to master)
- C1 `fix(federation): add SSRF protection to remote actor fetch (vuln-0001/vuln-0002)`
- C2 `fix(identity): close JWT algorithm-confusion via dedicated token secret (vuln-0004)`
- C3 `fix(federation): enforce required signed-header set + date window (vuln-0003)`
