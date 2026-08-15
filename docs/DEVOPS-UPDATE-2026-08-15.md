# UniFed — Engineering Update for DevOps

**Date:** 2026-08-15
**Scope:** Phase-3 product surfaces (backend P0 features + frontend consumption) and a CI test-DB fix.
**Branch:** `master` (deployed via fast-forward push)
**No infra/cloud changes** — Docker Compose staging unchanged.

## TL;DR
- Added 4 product feature areas to the API + matching frontend pages: **Smart-Campus (GIS)**, **LMS / Assignments**, **Research Hub**, **Admin Portal**. Federation hardening (STRIX F-04/05/06) also landed earlier in the same cycle.
- **CI was red** because the Phase-3 DDL files were in the wrong `db/schema/` location and CI never loaded them. **Fixed and pushed** (`24fa822`). Awaits CI re-run confirmation.
- Test DB is loaded from **authoritative SQL DDL files** (no `schema_migrations` tracking) — see the DB note below; this matters for any future migration workflow.

## Commits shipped
| SHA | What |
|-----|------|
| `deb8725` | Backend P0 features: Campus/GIS, LMS, Research Hub, Admin Portal, Federation hardening (201 RSpec examples, 0 failures) |
| `7f70e9a` | Frontend: `/campus`, `/assignments`, `/research`, `/admin` pages surfaced in the unified 5-tab nav; typed API client + Vitest + Playwright coverage |
| `24fa822` | **CI fix:** relocated Phase-3 DDL to repo-root `db/schema/` so `backend-ci.yml` loads it |

## New API endpoints (all under `/api/v1`)
**Campus / Smart-Campus** (`campus:manage` for writes)
- `GET /campus` — list campuses (node-scoped)
- `GET /campus/places` — list places (node-scoped)
- `GET /campus/near?lat=&lng=&radius=` — proximity search
- `POST /campus` — create campus/place (staff/admin)

**LMS / Assignments**
- `GET /assignments` — student sees enrolled; lecturer sees taught offerings
- `POST /assignments` — lecturer creates for an offering they teach (403 if not the teacher)
- `POST /assignments/:id/submit` — student submission
- `GET /assignments/:id/submissions` — lecturer list (403 if not owner)
- `PATCH /assignments/:id/submissions/:submission_id` — lecturer grade (403 if not owner)

**Research Hub** (`research:manage` for group creation)
- `GET /research/profiles`, `GET /research/groups`, `GET /research/publications`, `GET /research/projects`
- `POST /research/groups`, `POST /research/groups/:id/members` (group lead only)

**Admin Portal** (`admin:users` gated)
- `GET /admin/users` — user directory
- `GET /admin/stats` — node counts
- `POST /admin/users/:id/roles`, `DELETE /admin/users/:id/roles/:role_id` — RBAC assignment

**Federation (hardening, no new routes)**
- Inbox now persists `Follow` edges, tombstones `Delete` activities, and dedups replays via `Federation::ProcessedActivity`.
- `SignatureVerifier` fetches remote actor public keys over HTTP and enforces `keyId`-host == claimed actor.

## Frontend (Next.js, Pages Router)
- New routes wired to the real `/api/v1/*` endpoints (no longer mocked): `/campus`, `/assignments` (role-aware student/lecturer views), `/research`, `/admin`.
- Surfaced contextually in the **mandated 5-tab nav** (Home / Connect / Create / Discover / Profile) — nav itself unchanged.
- Test status: typecheck clean, **Vitest 12/12**, **Playwright smoke 9/9** (all 4 new pages included).

## CI / Test-DB note (important for DevOps)
`backend-ci.yml` builds the test DB by running `psql -f` over **`../db/schema/*.sql` from the `backend/` working dir = repo-root `db/schema/`**.
- New DDL **must** live at **repo-root `db/schema/`** with `unifed_phaseN_*.sql` names (alphabetical load order; `federation_hardening` must sort after `unifed_phase1_federation.sql`).
- Do **not** add DDL under `backend/db/schema/` — CI will silently skip it (`|| true` on the load loop) and feature specs will fail with "relation does not exist."
- There is **no `schema_migrations` tracking** — the repo-root SQL files are the source of truth for the schema. Any new table = a new `unifed_phaseN_*.sql` file there.

## Verification status
| Check | Result |
|-------|--------|
| Backend RSpec (Docker Ruby 3.3 + Postgres, fresh DB) | feature specs green: campus 6/6, lms 13/13, research ok, admin 6/6, federation_hardening 5/5 |
| Frontend typecheck / Vitest / Playwright smoke | green |
| CI `test` job | **fix pushed (`24fa822`); pending re-run confirmation via Actions screenshot** (no `gh`/token on this side to read CI directly) |

## Known / out-of-scope (for awareness)
- `postgres`/`redis` still published `0.0.0.0` (finding F-11) and `SECRET_KEY_BASE: change-me-in-prod` (F-12) — config-only, deliberately not changed this cycle.
- Live cross-instance ActivityPub federation is not fully live-tested; remote key fetch is implemented but external AP interop needs a real peer.
- Campus "map" is a category/proximity grid (haversine), not a tile-map library — by design, no new frontend dependency.

## Action items for DevOps
1. **Re-run CI** on `master` and confirm the `test` job flips green (was red on the prior run due to missing DDL).
2. When adding future tables: place DDL at repo-root `db/schema/unifed_phaseN_*.sql` and verify it loads via `psql -f` (the CI path).
3. Track F-11/F-12 for the staging-hardening backlog.
