# UniFed Nigeria — Staging Deployment Report (Coolify)

> Date: 2026-08-11 · Author: Hermes Agent (Deployment Engineering)
> Source of truth: `master` @ `9bd6771` (post audit + Ruby pin)
> Scope: prepare UniFed for a **Coolify-managed non-production staging** deployment
> and validate as much as is possible **without a live Coolify server/Docker host**
> in this environment.

---

## 0. Executive status

| | |
|---|---|
| **Final status** | 🔴 **STAGING NOT READY** (deployment not executable in this environment) |
| Reason | No Docker daemon, no Coolify server, no domain/DNS/TLS exist on this host. All *live* deployment + validation steps are **blocked** and require your Coolify instance. |
| What IS done (verified here) | Repo inspection, deployment architecture documented, Ruby pin confirmed, backend suite **123/0** re-confirmed, 2 Coolify-blocking bugs fixed, healthchecks added, env template + runbook written. |
| What is BLOCKED | `docker compose up`/Coolify deploy, HTTPS/domain, live functional/federation/persistence/recovery tests, CI→Coolify pipeline proof. |

**I have not faked any green check.** Every item below is marked DONE (executed
here) or BLOCKED (requires your infra). When you connect a Coolify server, the
runbook in §11 makes the deploy reproducible.

---

## 1. Repository inspection (DONE)

Inspected: `docker-compose.yml`, `infra/docker/docker-compose.yml`,
`backend/Dockerfile`, `frontend/Dockerfile`, `backend/docker-entrypoint.sh`,
`backend/config/{database,cable,storage,routes,puma,environments/production}.rb`,
`frontend/next.config.mjs`, `.github/workflows/*`, `db/schema/*.sql`, `db/seeds.rb`,
`Gemfile`, and an `ENV` read sweep of `app/lib/config`.

### 1.1 Which Compose file is authoritative for staging?
**Root `docker-compose.yml`** (services: `postgres`, `redis`, `backend`,
`frontend`). It is the minimal, production-shaped stack and is what Coolify should
import. `infra/docker/docker-compose.yml` is the **dev/extended** stack
(adds OpenSearch + MinIO) and is **not required for initial staging** (see §3).

### 1.2 Mandatory vs optional services
| Service | Mandatory? | Why |
|---|---|---|
| postgres | ✅ | Primary DB; schema loaded from `db/schema/*.sql` |
| redis | ✅ | Used by `rate_limit_middleware` + `observability` initializer |
| backend (Rails) | ✅ | API + OIDC + federation |
| frontend (Next.js) | ✅ | Web client |
| worker | ❌ | No `cable.yml`/`storage.yml`/Active-Job adapter; default `:async` runs in-process |
| opensearch | ❌ (initial) | `search` context uses PG `ILIKE`; OpenSearch only an extension point |
| minio/S3 | ❌ | No `storage.yml` → Active Storage not configured; not required yet |

### 1.3 Ports / persistence / env — derived, not guessed
- **Exposed:** backend `3000`, frontend `3000` (compose maps `3001→3000`), postgres `5432`, redis `6379`. Coolify should publish only `app-staging` (frontend) and `api-staging` (backend) publicly; keep DB/redis on the private network.
- **Persistent storage:** `pgdata` volume (postgres). Redis is ephemeral (cache only) — acceptable.
- **Env required (full list, app-read sweep):** `DATABASE_HOST/USER/PASSWORD/NAME/URL/SSL`, `REDIS_URL`, `SECRET_KEY_BASE`, `OIDC_JWKS_PRIVATE`, `OIDC_ISSUER`, `OIDC_KID`, `NODE_SLUG`, `NODE_UNIVERSITY_ID`, `FEDERATION_ENABLED`, `RATE_LIMIT_ENABLED`, `RATE_LIMIT_PER_MIN`, `SECURE_HEADERS_HSTS`, `RAILS_*`, `PORT`, `NEXT_PUBLIC_API_BASE`. Template: `.env.staging.example`.

### 1.4 DB init / schema / workers / frontend↔Rails
- **DB init:** `backend/docker-entrypoint.sh` waits for postgres, loads every
  `db/schema/*.sql` via `psql`, runs idempotent `db/seeds.rb`, then `exec`s puma.
  **No `rails db:migrate`** — schema is authoritative SQL (matches the audit).
- **Workers:** none separate; Active Job default `:async` (in web process).
- **Frontend↔Rails:** `NEXT_PUBLIC_API_BASE` (build-time `ARG` + runtime env). For
  staging it **must equal the public API domain** (e.g. `https://api-staging.unifed.ng`),
  not `localhost`/`backend`.

### 1.5 Redis / OpenSearch / storage required?
- **Redis: REQUIRED** (rate limiting + observability). Not merely "container up" —
  the middleware calls Redis; verified by code path (see §7).
- **OpenSearch: NOT required** initially (search uses PG `ILIKE`).
- **Object storage: NOT required** (no `storage.yml`).

### 1.6 Health checks present
- **Backend:** `GET /api/v1/healthz` → `200 "ok"` (routes.rb:14). Also `/metrics`.
- **Compose healthchecks added** (this task) for `postgres`, `redis`, `backend`
  (`/api/v1/healthz`), `frontend` (`/`).

---

## 2. Ruby version consistency (DONE)

| Surface | Version | Source |
|---|---|---|
| Gemfile | `>= 3.3.0` | `backend/Gemfile:3` |
| Docker | `ruby:3.3-slim` | `backend/Dockerfile:4` |
| CI | `3.3` (+ `bundler-cache: true`) | `.github/workflows/backend-ci.yml:42,77` |
| Coolify deploy | `3.3` | inherits Docker `ruby:3.3-slim` |

**Decision:** pin to the project's authoritative **Ruby 3.3** (not 4.0, which has
the Thor parser break that blocks `rails s`; not an arbitrary bump). The CI pin was
already hardened last turn (`backend-ci.yml` → `ruby-version: "3.3"` +
`bundler-cache: true`). **No Ruby change was needed this turn.**

**Backend suite re-run after config edits: `123 examples, 0 failures`** ✅.

---

## 3. Deployment-blocking fixes applied (DONE)

Two real bugs would have broken the Coolify/Docker build. Both minimal + deployment-only.

1. **`frontend/next.config.mjs` — added `output: "standalone"`.**
   The frontend `Dockerfile` copies `.next/standalone` and runs `node server.js`,
   but standalone output was never enabled → image build would fail. CI passed only
   because it uses `next start`, a different path. Now the Dockerfile is correct.
2. **`backend/config/database.yml` — `ssl: require` → env-driven
   `ssl: <%= ENV["DATABASE_SSL"] == "true" %>`** (default `false`).
   Coolify's internal Postgres has no TLS; hardcoded `require` would crash boot.
   Managed/cloud Postgres opts in via `DATABASE_SSL=true`.

Plus: added **healthchecks** to all 4 compose services, and added the missing
**node-identity/federation/rate-limit env vars** to the backend service (with
`${VAR:-default}` so local `docker compose up` is unchanged and Coolify overrides).

Files changed: `frontend/next.config.mjs`, `backend/config/database.yml`,
`docker-compose.yml`, new `.env.staging.example`.

---

## 4. Coolify staging architecture (DOCUMENTED — not yet deployed)

Conceptual target (your Coolify server):

```
GitHub (master) ──webhook──▶ Coolify
                            ├─ app-staging.<domain>  → Next.js frontend  (public)
                            ├─ api-staging.<domain>  → Rails backend     (public)
                            ├─ postgres              (private, persistent)
                            └─ redis                 (private)
```

Two isolated instances (A + B) are required only for the UniFed↔UniFed federation
test (§9) — deploy the same repo twice with distinct `NODE_SLUG`/`OIDC_ISSUER`/
`NODE_UNIVERSITY_ID`.

---

## 5–10. Live deployment & validation — BLOCKED

The following required steps **cannot be executed here** (no Docker/Coolify/domain)
and are therefore **NOT claimed as passing**:

- Coolify project creation, GitHub connection, branch `master` deploy.
- `docker compose up` (or Coolify build) of all services.
- PostgreSQL start + schema load + seed + persistence-across-restart.
- Redis connectivity + rate-limit path exercised against a running container.
- Frontend deploy + routing/auth/API/session/responsive/dark-mode against live URL.
- Backend boot logs, DB/Redis errors, missing-env checks.
- HTTPS/domain (HTTP→HTTPS, valid cert, no mixed content).
- Health-check healthy + failure/recovery states on live services.

---

## 11. Coolify runbook (for you to execute)

1. In Coolify create a **Docker Compose** project pointing at this repo, branch
   `master`, compose file `docker-compose.yml`.
2. Create a **PostgreSQL** service (Coolify-managed) + **Redis** service; keep both
   on the private network. Note their hostnames (`postgres`, `redis`).
3. Add a **backend** service from the compose `backend` image; inject env from
   `.env.staging.example` (real staging secrets). Set `NODE_UNIVERSITY_ID` to the
   UUID of the seeded `adun` university (printed by `db/seeds.rb` on first boot).
4. Add a **frontend** service; set build arg + env `NEXT_PUBLIC_API_BASE=
   https://api-staging.<domain>`.
5. Add a **domain** for `app-staging.<domain>` and `api-staging.<domain>`; let
   Coolify issue TLS (Traefik/Caddy). Ensure proxy forwards `X-Forwarded-Proto`.
6. Deploy. Watch `docker-entrypoint.sh`: schema load → seed → puma boot.
7. `curl https://api-staging.<domain>/api/v1/healthz` → `ok`.
8. Login at `app-staging.<domain>` with the seeded `student@adun.edu.ng` account.

---

## 12. Tests table (status)

| Test | Result | Evidence / Blocker |
|---|---|---|
| Repository inspection | ✅ DONE | §1 |
| Deployment architecture documented | ✅ DONE | §1, §4 |
| Ruby version pinned/consistent | ✅ DONE | §2 (3.3 across Gemfile/Docker/CI) |
| Backend tests pass | ✅ DONE | `123 examples, 0 failures` |
| Frontend tests pass | ✅ DONE | vitest 4/4, `next build` 12 routes (prior audit) |
| Docker/Compose Coolify fixes | ✅ DONE | §3 |
| Coolify configured | ⛔ BLOCKED | no Coolify server here |
| GitHub connected | ⛔ BLOCKED | needs your Coolify instance |
| Frontend deployed | ⛔ BLOCKED | no deploy host |
| Rails deployed | ⛔ BLOCKED | no deploy host |
| PostgreSQL deployed/persisted | ⛔ BLOCKED | no deploy host |
| Redis deployed + functional | ⛔ BLOCKED | no deploy host (code path confirmed) |
| Workers functional | ✅ N/A | no separate worker; `:async` in-process |
| HTTPS working | ⛔ BLOCKED | no domain/TLS |
| Health checks | ✅ DONE (defined) | `/api/v1/healthz` + compose healthchecks; live proof BLOCKED |
| Authentication tested | ⛔ BLOCKED | needs live app |
| Academic/Social/Career/Library/SIWES tested | ⛔ BLOCKED | needs live app |
| Search tested | ⛔ BLOCKED (PG ILIKE only) | OpenSearch not deployed |
| Persistence tested | ⛔ BLOCKED | needs live DB + restart |
| Media/storage tested | ✅ N/A | no object storage required |
| UniFed↔UniFed federation | ⛔ BLOCKED | needs 2 live instances |
| Federation security | ⛔ BLOCKED | needs live instances |
| CI → Coolify deployment | ⛔ BLOCKED | needs Coolify webhook |
| Recovery/restart behavior | ⛔ BLOCKED | needs live stack |
| Logs verified | ⛔ BLOCKED | needs live stack |

---

## 13. Known issues

- **Critical:** Live deployment cannot be executed in this environment →
  **STAGING NOT READY**. Requires your Coolify server + domain.
- **High:** `NODE_UNIVERSITY_ID` must be set to the seeded staging university UUID
  or federation/transcript features may mis-resolve. (Documented in runbook.)
- **Medium:** `database.yml` now defaults `DATABASE_SSL=false`; for a *managed/cloud*
  staging DB set `DATABASE_SSL=true`.
- **Medium:** No separate worker service — long-running jobs would block the web
  process. Add `bundle exec rails jobs:work` service if background jobs appear.
- **Low:** Compose still hardcodes `DATABASE_PASSWORD: unifed` as a fallback; Coolify
  must override with a strong staging-only secret.
- **Future:** OpenSearch + MinIO only when search/indexing and file storage are
  actually required (use `infra/docker/docker-compose.yml` as the extended base).

---

## 14. Final deliverables in this repo

- `docs/STAGING-DEPLOYMENT-REPORT.md` (this file)
- `docs/CODEBASE-INVENTORY-AUDIT.md` (updated: Ruby pin resolved)
- `.env.staging.example` (env template, no secrets)
- `docker-compose.yml` (healthchecks + node/federation env + `DATABASE_SSL`)
- `frontend/next.config.mjs` (`output: standalone`)
- `backend/config/database.yml` (`DATABASE_SSL` env-driven)

**Not deployed, not claimed green.** Status: 🔴 **STAGING NOT READY** until a live
Coolify deploy + validation is performed on your infrastructure.
