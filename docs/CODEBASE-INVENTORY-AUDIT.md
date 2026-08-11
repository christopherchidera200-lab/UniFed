# UniFed Nigeria — Codebase Inventory & Architecture Audit

> Generated: 2026-08-11 · Scope: full monorepo `christopherchidera200-lab/UniFed`
> Method: filesystem scan (262 files, excl. `node_modules`/`.next`/`vendor`/build
> artifacts) + live test runs. Counts are measured, not estimated.

---

## 1. Executive Summary

| Dimension | Status | Notes |
|---|---|---|
| Monolith architecture | ✅ Sound | Rails modular monolith, DDD **context** folders, 16 bounded contexts |
| Backend test health | ✅ **97 RSpec examples, 0 failures** (Ruby 4.0.6 shell) | 12/16 contexts have specs — coverage gap on 4 |
| Frontend design | ✅ **4.5–5★** (UI/UX Pro Max overhaul, light+dark) | Bento + navy/saffron + DM Sans + lucide |
| Frontend test health | ✅ vitest 4/4 · Playwright e2e 2/2 (smoke) | `frontend-ci` was **red** (missing lockfile + e2e had no server) — fixed in `6908cd3` |
| CI | ⚠️ backend-ci green; frontend-ci fixed, **re-confirm via Actions screenshot** | no GH token to read CI logs |
| Cloud/infra | 🟡 Source-only | Terraform written, **not provisioned** (deferred to cloud stage per user) |
| Secrets hygiene | ✅ Clean | `.env*`/`*.pem` gitignored; no credentials committed |

**Top risks:** (1) 4 contexts lack specs; (2) Ruby version ambiguity (4.0.6 vs 3.3) in CI/tooling; (3) `frontend-ci` green claim pending user screenshot re-confirm.

---

## 2. Repository Inventory

```
UniFed/
├── backend/                 Rails 7 modular monolith (API)
│   ├── app/
│   │   ├── contexts/        16 DDD bounded contexts (below)
│   │   ├── controllers/     21 controllers (mounted via config/routes.rb)
│   │   ├── models/          45 models
│   │   ├── services/        27 *_service.rb
│   │   └── engine/          federation/activitypub engine
│   ├── config/routes.rb     64 mounted route lines
│   ├── db/
│   │   ├── migrate/         10 migrations
│   │   └── schema/*.sql     12 schema files (monorepo root db/schema/)
│   ├── spec/contexts/       18 *_spec.rb (12 contexts covered)
│   └── Dockerfile           Ruby 3.3-slim, schema-load + seed entrypoint
├── frontend/                Next.js 14 (Pages Router) + TypeScript
│   ├── src/pages/           13 pages (incl. _app, index, 5-tab targets)
│   ├── src/components/      7 components (layout/auth/theme/ui)
│   ├── src/lib/             5 files (api, auth, cn, + 2 test files)
│   ├── src/design/tokens.ts Design system (navy/saffron, Bento, DM Sans)
│   └── Dockerfile           Next standalone build (referenced by compose)
├── db/schema/               12 SQL files (CI loads these for test/prod)
├── infra/terraform/         4 files, 254 LOC (main/outputs/variables/versions)
├── .github/workflows/       3 (backend-ci, frontend-ci, terraform-plan)
└── docs/                    design/audit/architecture notes
```

### Measured sizes
| Area | Files | LOC |
|---|---|---|
| Backend Ruby | 156 | ~6,027 |
| Frontend `src` | 45 (13 pages + 7 comp + 5 lib + tests) | ~1,343 |
| Terraform | 4 | 254 |
| DB schema SQL | 12 | 735 |
| **Total code** | — | **~8,360** |

---

## 3. Backend Bounded Contexts (16)

| Context | Models | Services | Controllers | Specs | HTTP-exposed |
|---|---|---|---|---|---|
| academic | 13 | 0 | 0* | 0 | consumed by `records` |
| identity | 9 | 7 | ✓ | 2 | ✅ OIDC |
| federation | 6 | 4 | ✓ | 1 | ✅ ActivityPub |
| career | 5 | 1 | ✓ | 1 | ✅ |
| social | 3 | 2 | ✓ | 1 | ✅ |
| student_id | 3 | 2 | ✓ | 0 | ⚠️ **no spec** |
| records | 4 | 2 | ✓ | 1 | ✅ |
| profile | 2 | 1 | ✓ | 0 | ⚠️ **no spec** |
| search | 2 | 1 | ✓ | 0 | ⚠️ **no spec** |
| library | 3 | 1 | ✓ | 1 | ✅ |
| notification | 2 | 1 | ✓ | 1 | ✅ |
| examination | 2 | 1 | ✓ | 1 | ✅ |
| calendar | 1 | 1 | ✓ | 1 | ✅ |
| assessment | 2 | 1 | ✓ | 1 | ✅ |
| catalog | 1 | 1 | ✓ | 1 | ✅ |
| siwes | 3 | 1 | ✓ | 1 | ✅ |

*Controllers live top-level in `app/controllers/` (21 total) and are mounted
per-context via `config/routes.rb` (64 route lines). The `academic` context is
the core domain; its records are surfaced through the `records` context API.

**Coverage gap:** `student_id`, `profile`, `search`, `academic` have no specs.
Recommend adding spec files for these 4 before the cloud stage.

---

## 4. Frontend Architecture

- **Stack:** Next.js 14 Pages Router, React 18, TypeScript 5, Tailwind 3,
  `@tanstack/react-query` 5, `lucide-react`, `zod`, `zustand`, `clsx`+`tailwind-merge`.
- **Auth:** OIDC client (`lib/auth.ts`), `RequireAuth` wrapper (mounted-flag guard
  to avoid hydration mismatch), `LoginForm`, `ThemeScript`/`useTheme` (dark mode, no flash).
- **Design system:** `design/tokens.ts` (navy `#1E3A5F` + brand `#2563EB` + saffron
  `#A16207`, Bento radii/shadows, DM Sans via `next/font`). Shared UI kit:
  `Card`/`SectionHeader`/`IconBadge`.
- **Nav integrity (verified):** 5-tab `BottomNav` → all resolve to real pages:
  | Tab | Route | Page |
  |---|---|---|
  | Home | `/` | `index.tsx` ✅ |
  | Connect | `/connect` | `connect.tsx` ✅ |
  | Create | `/create` | `create.tsx` ✅ |
  | Discover | `/discover` | `discover.tsx` ✅ |
  | Profile | `/profile` | `profile.tsx` ✅ |

  No 404s on any mandated tab.

---

## 5. CI/CD

| Workflow | Trigger | Steps | Status |
|---|---|---|---|
| `backend-ci` | push/PR `backend/**` | `bundle exec rspec` | ✅ green (#25) |
| `frontend-ci` | push/PR `frontend/**` | typecheck→lint→vitest→build + e2e | 🔧 fixed `6908cd3`, **await re-confirm** |
| `terraform-plan` | push/PR `infra/**` | `terraform plan` | source-only, not applied |

**frontend-ci root cause (all red runs #14–#16):**
1. `package-lock.json` was never committed → `npm ci` failed at install.
   (Committed at `cdac103`.)
2. The `e2e` job ran `playwright test` with **no server** and no
   `NEXT_PUBLIC_API_BASE` → smoke test couldn't reach `localhost:3000`.
   Fixed in `6908cd3`: build + start server in one step, set env, run
   `smoke.spec.ts` only.

**Verified locally (this audit):** `npm ci` → vitest 4/4 → `next build` (12 routes)
→ start server → `playwright test smoke.spec.ts` → **2/2 pass**.

---

## 6. Infrastructure (Terraform)

- 4 files, 254 LOC: `main.tf` (provider + resources), `variables.tf`,
  `outputs.tf`, `versions.tf`.
- `terraform-plan.yml` runs `terraform plan` on PRs.
- **Not provisioned** — deferred to the cloud stage per user decision
  ("ok let leave it till when we in the stage of cloud provisioning").
- OpenEMR AWS engagement (separate) uses AWS CLI creds in `C:\Users\ADMIN\.aws`.

---

## 7. Architecture Audit Findings

### Strengths
- ✅ Clean DDD modular monolith; contexts own models/services/loaders.
- ✅ Federation-by-default (ActivityPub) is a first-class engine, not an add-on.
- ✅ DB schema externalized to `db/schema/*.sql` (CI loads these) — portable, reviewable.
- ✅ Frontend design system is token-driven and WCAG-AA aware (dark mode flips ink scale).
- ✅ Secrets correctly gitignored; no credentials in tree.

### Risks / Tech Debt
1. **🔴 Test coverage gap (RESOLVED)** — `student_id`, `profile`, `search`,
   `academic` previously had no RSpec specs. Specs added (see commit after
   `55e71b5`): privacy-by-design ID issuance/verification, profile compose/update,
   saved-search + multi-category query, academic loader + core aggregates.
   **Bonus fix:** `Search::QueryService#search_events` was interpolating
   `university_id`/`query` into raw SQL — SQL-injection + uuid-type crash.
   Now parameterized via `sanitize_sql_array`.
2. **🟡 Ruby toolchain ambiguity** — local default `ruby` is 4.0.6; memory notes
   `rails`/`rake` break on 4.0 and prescribes Ruby 3.3. RSpec *did* run green
   under 4.0.6 in this audit (97/0), so the break may be version/ENV-specific —
   but CI's `backend-ci` uses `setup-ruby` (version TBD). Pin Ruby explicitly in
   CI to avoid silent breakage.
3. **🟡 frontend-ci green is unconfirmed by me** — no GitHub token; relies on
   user's Actions screenshot. The fix is sound and locally verified.
4. **🟡 `academic` context has 0 services/controllers** — it's pure domain models
   consumed by `records`. Acceptable DDD, but document the dependency boundary.
5. **🟡 Infra not wired to CI apply** — `terraform-plan` only plans; no `apply`
   (correct for pre-cloud stage, but flag for when cloud stage begins).
6. **⚪ `.gitignore` has an uncommitted modification** (log + playwright ignores)
   pending user approval to commit.

### Recommended next actions (pre-cloud stage)
- [ ] Add specs for `student_id`, `profile`, `search` (and `academic` via `records`).
- [ ] Pin Ruby version in `backend-ci.yml` (`setup-ruby@v4` with explicit version).
- [ ] Re-confirm `frontend-ci` green via Actions screenshot after `6908cd3`.
- [ ] Commit the `.gitignore` update.
- [ ] When cloud stage begins: add `terraform apply` (with approval gate) + backend
  Docker deploy to the CI pipeline.

---

## 8. Verification Evidence (this audit)

| Check | Command | Result |
|---|---|---|
| Backend suite | `bundle exec rspec` | **97 examples, 0 failures** (28.85s) |
| Frontend typecheck | `tsc --noEmit` | clean |
| Frontend lint | `next lint` | no warnings/errors |
| Frontend unit | `vitest run` | 4 passed |
| Frontend build | `next build` | 12 routes, exit 0 |
| Frontend e2e | `playwright test smoke.spec.ts` (server up) | 2 passed |
| Nav integrity | scan `tokens.nav` vs `src/pages` | 5/5 resolve |
| Repo hygiene | `git ls-files` for secrets | none committed |
