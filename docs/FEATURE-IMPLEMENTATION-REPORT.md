# UniFed Feature Implementation Report — P0 Product Expansion

**Date:** 2026-08-15
**Scope:** Incremental product-feature implementation per the HERMES mission. No cloud/infra changes. Backend is a Rails 8.1 modular monolith; all new slices follow the existing bounded-context pattern (models under `app/contexts/<ctx>/`, controllers under the standard `app/controllers/api/v1/` path, one DDL file per context in `db/schema/` for the staging DB).

**Test result:** `bundle exec rspec` → **201 examples, 0 failures** (151 pre-existing + 50 new feature specs). All new endpoints have request-level coverage; all new models have unit coverage.

---

## What was implemented

### P0-1 — GIS / Smart Campus (Smart_Campus context)
- `Campus::Campus` (campuses per university) + `Campus::Place` (POIs: lecture halls, labs, library, hostels, hostels, parking, shuttle stops, etc.).
- `Campus::CampusService`: list, `near` (bounding-box + Ruby haversine sort — **PostGIS-independent**; a `geography` column is added only when the `postgis` extension is present), `create_place!`.
- `CampusController` (standard path): `GET /api/v1/campus/places`, `GET /places/:id`, `GET /campus/near?lat&lng&radius`, `POST /campus/places` (staff/admin, `campus:manage`).
- **Status:** 12/12 specs green.

### P0-2 — Assignments / LMS (Lms context)
- `Lms::Assignment` + `Lms::Submission` (uuid keys, jsonb rubric, score/feedback, status machine draft→submitted→graded).
- `Lms::AssignmentService`: create (ownership-checked), publish, submit (student, published-only), grade (lecturer-only, advisory-AI-ready), `for_student`/`for_course_offering`.
- `AssignmentsController`: index (lecturer→taught; student→enrolled), show, create (staff + `academic:write`), submit, grade (PATCH), submissions (lecturer). Strict BOLA-style ownership (403 on cross-actor access).
- **Status:** 12/12 specs green.

### P0-3 — Research Hub (Research context)
- `Research::ResearchProfile`, `ResearchGroup` (+`GroupMembership`), `Publication`, `ResearchProject`.
- `ResearchService` + `ResearchController`: profiles search, groups list/create (staff+`research:manage`), show group (with members), add member (group lead or `research:manage`).
- **Status:** 14/14 specs green.

### P0-4 — Administration Portal (AdminController)
- `GET /api/v1/admin/users` (paginated, searchable, role-filterable), `GET /api/v1/admin/stats` (node counts), `POST /api/v1/admin/users/:id/roles` (assign, via `Identity::RoleService`).
- Every action gated by `admin:users` (or `admin?`). No self-service, no federation exposure.
- **Status:** 6/6 specs green.

### P0-5 — Federation hardening (F-04 / F-05 / F-06)
- **F-04 (signature verification):** `SignatureVerifier` now (a) fetches the remote actor's public key over HTTPS with a 5s timeout + 1h cache when the signer is unknown, and (b) **enforces that the signing `keyId` identifies the same actor claimed in the activity body** — closes the "sign-as-someone-else" gap.
- **F-05 (Follow / Delete):** `Follow` now creates a **persisted edge** (`Federation::Follow`) instead of a no-op; `Delete` now **tombstones** the referenced `Federation::Activity` (new `deleted_at`) / `Social::Post`.
- **F-06 (replay protection):** new `Federation::ProcessedActivity` table (unique `ap_id`); the inbox handler rejects a second delivery of the same activity id (`replay_detected`, 422).
- **Status:** 10/10 federation specs green (existing + new F-04/F-05/F-06).

---

## Security notes (carried forward)
- New write endpoints are RBAC-gated; ownership/permission failures return **403** (not 422) so authorization is unambiguous.
- LMS grading is lecturer-only and explicitly **not** auto-applied by any AI path (advisory-only by design).
- Federation replay/impersonation gaps from the prior white-box assessment are now closed at the inbox boundary.
- Database, Redis, and secrets remain on the staging Compose network (F-11/F-12 are deployment concerns, out of this task's scope per RoE).

## Not done in this pass (explicitly out of scope)
- **Frontend UI** for campus map, assignments, research, admin. Backend APIs exist and are tested; the Next.js app does not yet surface these (would be "faking" features if claimed). These remain 🔴 until UI lands.
- **P1 features** (messaging, marketplace, alumni, wellbeing) — deferred per priority.
- **Cloud/infra** (AWS, K8s, Terraform) — explicitly excluded by the mission scope rule.

## Migration / DB note
New tables are created via Rails migrations AND mirrored as authoritative DDL in `db/schema/*.sql` (the staging DB is loaded from DDL). Both must stay in sync. The DDL for all four new contexts has been applied to the staging `unifed_test` database used by CI-equivalent runs.

## Roadmap (next)
1. Frontend: surface Campus map, Assignments/LMS, Research Hub, Admin portal within the unified 5-tab nav.
2. P1: internal messaging, marketplace, alumni, wellbeing.
3. Live federation wiring (real remote key fetch + signed delivery) behind a feature flag.
4. PostGIS enablement on staging for true geo queries (code already degrades gracefully without it).
