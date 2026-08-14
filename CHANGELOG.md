# Changelog

## 2026-08-14 — Post-Staging Product Readiness
- **Auth-gating split:** Catalog, Library, Events, Career browse endpoints are now public (no token); Profile, Academic Records, Create/Post, and authenticated career actions remain token-protected (deny-by-default `before_action :authenticate!` in `BaseController`). Public reads are scoped to the node university (`NODE_UNIVERSITY_ID`), never a caller-supplied value.
- **Real profile:** `profile.tsx` now fetches the authenticated user's real data via `GET /api/v1/profile`; hardcoded "ADUN Student" / "student@adun.edu.ng" removed. Loading/error/missing states added. (Endpoint already existed and was correctly authorized — reused.)
- **Signup / registration:** New `POST /api/v1/auth/register` backed by `Identity::RegistrationService` (Argon2 passwords, server-side role assignment, duplicate-email 409, password policy, transaction-safe, returns tokens for auto-login). Users cannot self-assign privileged roles. New `signup.tsx` page + login link.
- **Seed data:** Added idempotent demo content — 10 courses (CSC programme) + 8 library resources + a `member` role. Fixed pre-existing seed bugs (invalid columns) so `db/seeds.rb` runs against the committed schema.
- **Bug fixes:** `resource :profile` was unroutable (resolved to non-existent `ProfilesController`) — now explicit routes; `BaseController` deny-by-default fixes latent `ArgumentError` in `skip_before_action` calls.
- **Tests:** Backend RSpec 143/0 (+20 new: registration, auth-gating, profile, seed idempotency). Frontend vitest 7/7, typecheck + `next build` (standalone) green.
- **Docs:** `docs/POST-STAGING-PRODUCT-READINESS-REPORT.md`.
- **Known limitation:** Playwright E2E not executed (no reachable integrated staging stack); all other automated gates pass.
