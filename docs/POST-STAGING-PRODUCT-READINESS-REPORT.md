# UniFed Nigeria — Post-Staging Product Readiness Report

**Date:** 2026-08-14
**Scope:** Auth-gating split · real logged-in profile · user signup/registration · real course + library seed data
**Status:** IMPLEMENTED & UNIT/INTEGRATION-VERIFIED. E2E (Playwright) BLOCKED (no reachable integrated staging stack from the build host).

---

## 1. Executive Summary

All four product-readiness improvements were implemented against the **actual** repository (no assumptions; every endpoint was confirmed in `config/routes.rb` and every model in `db/schema/*.sql` before editing). The backend test suite is **143 examples, 0 failures** (was 123/0; +20 new). Frontend **typecheck, build, and vitest all pass**. During implementation we also **fixed several pre-existing bugs** that would have broken staging (see §11).

No source was modified outside the four workstreams except the necessary bug fixes required for the seed/registration/profile endpoints to actually function.

## 2. Files Changed

**Backend**
- `config/routes.rb` — added `POST /api/v1/auth/register`; changed `resource :profile` (broken: resolved to non-existent `ProfilesController`) to explicit `get/patch "profile"` → `profile#show/update`.
- `app/controllers/api/v1/base_controller.rb` — added `before_action :authenticate!` (deny-by-default) + `node_university` helper. Fixes a latent `ArgumentError` in `AuthController`/`FederationController` `skip_before_action` calls.
- `app/controllers/api/v1/auth_controller.rb` — `register` action; added `register` to the public (`skip_before_action`) list.
- `app/controllers/api/v1/catalog_controller.rb` — `courses`/`offerings` public.
- `app/controllers/api/v1/library_controller.rb` — `resources` public (scoped to node university).
- `app/controllers/api/v1/calendar_controller.rb` — `events` public.
- `app/controllers/api/v1/career_controller.rb` — `opportunities` public.
- `app/contexts/identity/app/services/identity/registration_service.rb` — **NEW**: Argon2 password hashing, server-side role assignment, duplicate-email 409, password policy, transaction-safe, returns tokens (reuses `PasswordAuthService.success` for auto-login).
- `app/contexts/identity/lib/identity.rb` — require the new service.
- `db/seeds.rb` — fixed pre-existing column mismatches; added idempotent 10 demo courses + 8 library resources + `member` role; set matric pattern on the seed university.

**Frontend**
- `src/lib/api.ts` — added `profile(token)` + `register(payload)` (surfaces server `error` reason); public browse methods (`catalogCourses`/`events`/`opportunities`/`libraryResources`) now use token-less `publicFetch`.
- `src/lib/auth.ts` — `storeTokens()` helper (reuses existing session store for post-register auto-login).
- `src/pages/profile.tsx` — rewritten to fetch the real profile; removed hardcoded "ADUN Student"/"student@adun.edu.ng"; loading/error/missing states.
- `src/pages/catalog.tsx`, `library.tsx`, `events.tsx`, `career.tsx` — removed `RequireAuth` wrapper; public fetch (no token).
- `src/pages/index.tsx` — updated to token-less browse calls.
- `src/pages/signup.tsx` — **NEW**: registration page (design-system consistent).
- `src/pages/login.tsx` — "Create an account" link to `/signup`.
- `src/lib/api.test.ts` — added `register`/`profile` client tests.

**Tests**
- `spec/contexts/identity/registration_spec.rb` (NEW)
- `spec/requests/auth_gating_spec.rb` (NEW)
- `spec/contexts/catalog/seed_idempotency_spec.rb` (NEW)

**Docs**
- `docs/POST-STAGING-PRODUCT-READINESS-REPORT.md` (this file)
- `CHANGELOG.md` (entry added)

## 3. Auth-Gating Changes
- Deny-by-default: `BaseController#authenticate!` now runs for every API controller unless explicitly skipped.
- **Public (no token):** `GET /api/v1/catalog/courses`, `/catalog/offerings`, `/library/resources`, `/calendar/events`, `/career/opportunities`. These scope data to the **node university** (`NODE_UNIVERSITY_ID`), never to a caller-supplied university.
- **Protected (token required, 401 otherwise):** `GET /api/v1/profile`, academic records (`/academic/.../records`), `feed#create` (posts), library borrow/return, career apply/save/recommendations/applications, federation inbox.
- Frontend: catalog/library/events/career pages no longer wrap in `RequireAuth` and fetch publicly; profile/create/academic remain guarded.

## 4. Profile Implementation
- `GET /api/v1/profile` was already present and **correctly authorized** (returns `Profile::ProfileService.for_user(current_user)` — the caller's own profile, never an arbitrary ID). Reused; no new endpoint.
- `profile.tsx` calls `unifedApi.profile(token)` and renders `display_name`, `email`, `actor_type`, `bio`, `skills`. Hardcoded demo identity removed. Loading / error / missing-field states handled.

## 5. Registration Implementation
- `POST /api/v1/auth/register` → `Identity::RegistrationService.register`.
- Validates name/email (RFC5322) / password policy (≥8 chars, upper+lower+digit+symbol).
- Duplicate email per node university → `409 conflict`.
- Password hashed with **Argon2** (`Identity::Credential.hash_password`).
- **Roles assigned server-side only:** base `member` role; optional `student` linkage when a valid, unclaimed matric number is supplied. `role` / `actor_type` params are **ignored** — admin/staff are never grantable.
- On success returns `{access_token, refresh_token}` (auto-login via existing `PasswordAuthService.success`); no password in response; transaction-safe.

## 6. Course Seed Implementation
- 10 demo courses under the seeded CSC programme (Cybersecurity Fundamentals, Cloud Computing, Computer Networks, Operating Systems, Database Systems, Software Engineering, Web Technologies, Information Assurance, Digital Forensics, Data Structures & Algorithms).
- Only real schema columns set (`code`, `title`, `credit_units`, `level`, `semester`, `programme_id`, `prerequisites`). No `description`/`faculty`/`department`/`lecturer` columns exist in the schema, so those are **not** fabricated.
- Clearly demo data; `find_or_create_by!` → idempotent.

## 7. Library Seed Implementation
- 8 demo resources (lecture notes / study guides / references) with `title`, `author`, `resource_type` (book/ebook/journal/past_question). No `url`/`description` columns exist, so none fabricated. Original demo descriptions only — no copyrighted material.

## 8. API Endpoints Added/Changed
- **Added:** `POST /api/v1/auth/register`
- **Changed:** `GET /api/v1/profile` route (explicit path; was unroutable). Catalog/library/calendar/career browse endpoints made public.

## 9. Security Considerations
- **No privilege escalation:** `register` never reads a `role` param; only `member`/`student` (via validated matric) are assignable. Verified by spec `prevents privilege escalation via client-supplied role/actor_type`.
- **No IDOR:** profile derives identity from the authenticated token; academic records require auth.
- **Password safety:** Argon2; no plaintext logging; no password in responses.
- **Public endpoints** expose only intended browse data (node-scoped); no PII, no profiles, no academic records.
- **Rate limiting** (existing `RateLimitMiddleware`) still wraps all endpoints.

## 10. Tests Executed
| Suite | Command | Result |
|---|---|---|
| Backend RSpec (full) | `bundle exec rspec` | **PASS — 143 examples, 0 failures** |
| Frontend typecheck | `tsc --noEmit` | **PASS** |
| Frontend unit (vitest) | `vitest run` | **PASS — 7 passed** |
| Frontend build | `next build` | **PASS — STANDALONE_OK** |
| Backend healthz | `GET /api/v1/healthz` | **PASS** (route unchanged; exercised by suite) |
| E2E (Playwright) | `playwright test` | **BLOCKED** — no reachable integrated backend+frontend stack from build host |

### New backend specs (all PASS)
- `registration_spec.rb`: success (Argon2 + tokens), weak password (422), missing email (422), duplicate email (409), role-escalation prevention, matric-linked student, node-not-configured (503).
- `auth_gating_spec.rb`: catalog/library/calendar/career public (200 unauth); profile 401 unauth; academic records 401 unauth; authenticated profile returns own data & no password leakage.
- `seed_idempotency_spec.rb`: stable across two runs; demo course + library content created.

## 11. Remaining Limitations / Bugs Fixed
**Pre-existing bugs fixed during this work (would have broken staging):**
1. `db/seeds.rb` referenced non-existent columns: `University#code`→`short_name`, `country`→`country_iso`, `Faculty`/`Department#slug`→`code`, `Student#first_name/last_name/programme/level` (removed), `EmployerProfile#contact_email` (removed), `LibraryResource`→`Library::LibraryResource`, `Identity::Role#university`→`university_id`. Seed now runs cleanly.
2. `resource :profile` resolved to non-existent `ProfilesController` → profile endpoint was unroutable. Fixed.
3. `BaseController` lacked `before_action :authenticate!`, so `AuthController`/`FederationController` `skip_before_action :authenticate!` raised `ArgumentError` at class load. Fixed (deny-by-default).

**Known limitations (not blockers):**
- Playwright E2E not run (no integrated host). Static/unit/integration coverage is green.
- `index.tsx` still shows a generic "Welcome back" / "ADUN Student" greeting; the task's hardcoded-identity requirement targets `profile.tsx` (fixed). Home greeting left as a cosmetic follow-up.
- Email verification is **not** implemented (documented as future enhancement, not faked).

## 12. Recommended Next Steps
1. Run Playwright E2E against a reachable staging stack (provide URL/DB creds).
2. Add email-verification flow (currently auto-login on register).
3. Replace `index.tsx` "ADUN Student" greeting with the real profile name.
4. Confirm `NODE_UNIVERSITY_ID` is set in Coolify so public endpoints resolve the correct node.

## 13. Acceptance Criteria — Status
- [x] Catalog accessible without login
- [x] Library accessible without login
- [x] Events accessible without login
- [x] Career accessible without login
- [x] Profile requires authentication
- [x] Academic records require authentication
- [x] Create functionality requires authentication
- [x] profile.tsx contains no hardcoded demo user identity
- [x] Profile displays the authenticated user's actual API data
- [x] Profile API is properly authorized
- [x] Signup page exists
- [x] Signup backend endpoint exists
- [x] Registration validation works
- [x] Duplicate accounts are rejected
- [x] Passwords are securely handled (Argon2)
- [x] Users cannot self-assign privileged roles
- [x] Successful signup integrates with existing authentication (auto-login)
- [x] Course seed data exists
- [x] Library seed data exists
- [x] Seeds are idempotent
- [x] Existing staging demo data still works (seed runs; demo student intact)
- [x] Backend tests pass (143/0)
- [x] Frontend tests pass (vitest 7/7)
- [x] Build passes (STANDALONE_OK)
- [x] Health check passes
- [x] No security regression identified
- [~] E2E tests pass — **BLOCKED** (no integrated host); all other automated gates green
