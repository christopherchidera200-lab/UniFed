# Coolify Staging — Pre-Deploy Check (UniFed Nigeria)

> Date: 2026-08-11 · Status: **PRE-DEPLOY VERIFIED (files), deployment NOT executed**
> Companion to `docs/STAGING-DEPLOYMENT-REPORT.md` and `.env.staging.example`.
> No live deployment performed (no Coolify host / Docker daemon in this env).

---

## 1. Selected Compose file

**Authoritative for staging: root `docker-compose.yml`** (4 services:
`postgres`, `redis`, `backend`, `frontend`).

`infra/docker/docker-compose.yml` is the **extended DEV stack** and is NOT used
for staging (reasons in §2). It remains source-only.

---

## 2. Why root `docker-compose.yml` (comparison)

| Dimension | `docker-compose.yml` (root) ✅ | `infra/docker/docker-compose.yml` ❌ |
|---|---|---|
| Services | postgres, redis, **backend, frontend** | postgres, redis(+pw), **opensearch, minio**, backend (no frontend) |
| RAILS_ENV | `production` | `development` |
| Dockerfile | `backend/Dockerfile` (Ruby 3.3) | `infra/docker/Dockerfile.rails` |
| Build context | immutable image (COPY src) | bind-mounts `../..` source (mutable, not reproducible) |
| DB init | `docker-entrypoint.sh`: schema load + seed (deterministic) | `rails server` only; no schema-load entrypoint |
| Redis | no password (`redis-cli ping` works) | `--requirepass unifed` (password in compose) |
| Secrets | via `${VAR:-default}`, no real secrets | **hardcoded** `Un1Fed!Os2026` / `Un1Fed!Mm2026` |
| Healthchecks | postgres, redis, backend, frontend | only postgres, redis, opensearch |
| Networks | default (none declared) | default (none declared) |

**Why root is appropriate for Coolify staging:**
1. It is the only file that includes the **frontend** (staging must serve the web client).
2. `RAILS_ENV=production` + immutable image = reproducible, audited artifact.
3. Deterministic DB init via entrypoint (schema SQL + idempotent seed) — no `rails db:migrate` drift.
4. No hardcoded secrets; all sensitive values are `${VAR:-default}` placeholders Coolify overrides.
5. Healthchecks on every service → Coolify can probe readiness.
6. Minimal footprint (no OpenSearch/MinIO) matches the audit decision: search uses
   PG `ILIKE`; no `storage.yml` ⇒ object storage not required initially.

The two files were **not merged or rewritten** — root is adopted as-is (plus the
minimal, already-committed staging edits: healthchecks, `DATABASE_SSL`,
node/federation env; see §9).

---

## 3. Required Coolify services

| Service | Image | Mandatory | Role |
|---|---|---|---|
| postgres | `postgres:16-alpine` | ✅ | primary DB (persistent) |
| redis | `redis:7-alpine` | ✅ | rate-limit + observability cache |
| backend | build `backend/Dockerfile` | ✅ | Rails API + OIDC + federation |
| frontend | build `frontend/Dockerfile` | ✅ | Next.js web client |
| worker | — | ❌ | none (see §8) |
| opensearch | — | ❌ | not for initial staging |
| minio/s3 | — | ❌ | not required (no `storage.yml`) |

Deploy as a **Coolify "Docker Compose" project** importing `docker-compose.yml`
from `master`. Coolify creates the network; services resolve by compose name
(`postgres`, `redis`, `backend`, `frontend`) on Coolify's internal network.

---

## 4. Required environment variables (backend)

All are read by the app (env sweep of `app/lib/config`). Categories:

**Runtime:** `RAILS_ENV=production`, `RACK_ENV=production`, `RAILS_MAX_THREADS=5`,
`RAILS_SERVE_STATIC_FILES=true`, `PORT=3000`.

**PostgreSQL:** `DATABASE_HOST=postgres`, `DATABASE_USER`, `DATABASE_PASSWORD`,
`DATABASE_NAME=unifed`, `DATABASE_URL`, `DATABASE_SSL=false` (internal PG has no TLS).

**Redis:** `REDIS_URL=redis://redis:6379/0`.

**Rails secret + OIDC (RS256 JWKS):** `SECRET_KEY_BASE`, `OIDC_JWKS_PRIVATE`
(PEM/base64 PEM), `OIDC_KID`, `OIDC_ISSUER=https://api-staging.<domain>`.

**Node identity + federation:** `NODE_SLUG=adun-staging`, `NODE_UNIVERSITY_ID`
(**must be set post-seed — see §7**), `FEDERATION_ENABLED=true`.

**Frontend (build arg + runtime):** `NEXT_PUBLIC_API_BASE=https://api-staging.<domain>`
(**public domain, baked at build time — NOT `http://backend:3000`**).

**Rate limiting / headers:** `RATE_LIMIT_ENABLED=true`, `RATE_LIMIT_PER_MIN=120`,
`SECURE_HEADERS_HSTS=true`.

**Optional:** `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_ENDPOINT` (leave blank if none).

Full template with placeholders (no secrets): `.env.staging.example`.

---

## 5. Persistent volumes

| Volume | Service | Purpose | Survives restart? |
|---|---|---|---|
| `pgdata` | postgres | `/var/lib/postgresql/data` | ✅ yes (named volume) |
| (none) | redis | ephemeral cache only | n/a (cache, safe to lose) |
| (none) | backend/frontend | stateless images | n/a |

No other volumes required. Data persistence = `pgdata` only.

---

## 6. Ports / domains

| Service | Container port | Publish? | Domain (Coolify) |
|---|---|---|---|
| frontend | 3000 | ✅ public | `app-staging.<domain>` |
| backend | 3000 | ✅ public (API) | `api-staging.<domain>` |
| postgres | 5432 | ❌ private | internal only |
| redis | 6379 | ❌ private | internal only |

Within the compose network the frontend reaches the backend at `http://backend:3000`.
For the **browser**, `NEXT_PUBLIC_API_BASE` must be the public `https://api-staging.<domain>`
(set as Coolify build arg). Do not expose postgres/redis publicly.

---

## 7. `NODE_UNIVERSITY_ID` derivation (documented, not guessed)

`NODE_UNIVERSITY_ID` is **not** a magic value — it must equal the UUID of the
university node created by the seed.

Source: `backend/db/seeds.rb` (idempotent) creates:
```ruby
uni = Academic::University.find_or_create_by!(slug: "adun") { |u| ... }
puts "university: #{uni.slug} (#{uni.id})"   # prints the UUID
```
The backend container's `docker-entrypoint.sh` runs this seed on first boot and
**prints `university: adun (<UUID>)` to the backend logs**.

**Procedure (on Coolify):**
1. Deploy with `NODE_UNIVERSITY_ID` left at its placeholder (or any value).
2. Read the backend container logs; copy the `<UUID>` from `university: adun (<UUID>)`.
3. Set `NODE_UNIVERSITY_ID=<UUID>` in the Coolify backend env.
4. Redeploy (or restart) the backend service so it picks up the correct node.

Federation/transcript features resolve the local node via this UUID — getting it
wrong causes mis-resolved actor/transcript behaviour. This is the single most
important post-boot configuration step.

---

## 8. Worker requirements

**No separate worker service is required for initial staging.** Evidence:
- No `cable.yml`, no `storage.yml`, no Active-Job adapter configured in the repo.
- No `jobs:work` / `sidekiq` / `solid_queue` / `good_job` in either compose file.
- Rails default Active Job adapter (`:async`) runs jobs **in-process** inside the
  web (puma) process.

Redis is used (rate-limit middleware + observability initializer) but as an inline
cache, not a job queue. If background jobs appear later, add a
`bundle exec rails jobs:work` service (and a real queue adapter) — out of scope now.

---

## 9. Database initialization procedure

`backend/docker-entrypoint.sh` (runs as the container ENTRYPOINT before puma):
1. Wait for Postgres (`pg_isready`).
2. Load every `db/schema/*.sql` via `psql ... -f` (deterministic; no `db:migrate`).
3. Run idempotent `db/seeds.rb` (`rails runner`) → creates `adun` university, demo
   student (`student@adun.edu.ng` / `Passw0rd!`), employer + opportunity, events.
4. `exec puma -p 3000 -e production`.

Postgres itself is initialized by the image on first `pgdata` volume creation.
Data persists across container/stack restarts via the `pgdata` volume.

---

## 10. Health checks

| Service | Probe |
|---|---|
| postgres | `pg_isready -U unifed` |
| redis | `redis-cli ping` |
| backend | `curl -fsS http://localhost:3000/api/v1/healthz` → `200 ok` |
| frontend | `curl -fsS http://localhost:3000` |

Plus app-level: `GET /api/v1/healthz` and `GET /metrics` (routes.rb). Coolify
should use the container healthchecks for readiness gating.

---

## 11. Startup / deployment commands

Local (reference):
```bash
docker compose up --build          # root compose
# or: backend only schema/seed check:
docker compose run backend rails runner db/seeds.rb
```

Coolify (your server):
- Project type: **Docker Compose**, repo `christopherchidera200-lab/UniFed`,
  branch `master`, compose path `docker-compose.yml`.
- Coolify builds each service image from its Dockerfile.
- Domains: `app-staging.<domain>` → frontend, `api-staging.<domain>` → backend;
  Coolify provisions TLS.
- Deploy; watch backend logs for `university: adun (<UUID>)` + puma boot.

---

## 12. Known blockers (honest)

- 🔴 **No Coolify host / Docker daemon in this environment** → live deploy + all
  live validation (functional, federation, persistence, recovery, HTTPS) are
  **BLOCKED** and must run on your Linux staging server.
- 🟡 `NODE_UNIVERSITY_ID` must be set from the seeded UUID post-first-boot (§7).
- 🟡 `NEXT_PUBLIC_API_BASE` must be the **public** API domain in Coolify (build arg),
  not `http://backend:3000`.
- 🟡 `DATABASE_SSL=false` is correct for Coolify internal PG; set `true` for a
  managed/cloud staging DB.
- 🟡 Compose still has a `unifed` DB-password fallback; Coolify must override with a
  strong staging-only secret.
- 🟢 OpenSearch / MinIO / worker: not required for initial staging.

---

## 13. Exact steps to perform on the Coolify server

1. Provision a Linux VPS (Ubuntu 22.04+), install Docker + open ports 80/443/8000.
2. Install Coolify: `curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash`
   (run as root on the Linux host — **not** on the Windows dev box).
3. Complete the Coolify wizard at `http://<server-ip>:8000`; create your project.
4. Create a **PostgreSQL** service and a **Redis** service in Coolify (private net).
5. Add a **Docker Compose** resource → repo `master`, file `docker-compose.yml`.
6. In the backend env, set real staging secrets: `SECRET_KEY_BASE`,
   `OIDC_JWKS_PRIVATE`, `OIDC_ISSUER`, `OIDC_KID`, `DATABASE_PASSWORD`,
   `NODE_SLUG`, `FEDERATION_ENABLED=true`, `RATE_LIMIT_*`, `SECURE_HEADERS_HSTS=true`,
   `DATABASE_SSL=false`.
7. In the frontend env/build-arg, set `NEXT_PUBLIC_API_BASE=https://api-staging.<domain>`.
8. Add domains `app-staging.<domain>` and `api-staging.<domain>`; let Coolify issue TLS.
9. Deploy. Read backend logs for `university: adun (<UUID>)`.
10. Set `NODE_UNIVERSITY_ID=<UUID>` in backend env; redeploy backend.
11. `curl https://api-staging.<domain>/api/v1/healthz` → `ok`.
12. Login at `app-staging.<domain>` with `student@adun.edu.ng` / `Passw0rd!`.

(Detailed narrative version: `docs/STAGING-DEPLOYMENT-REPORT.md` §11.)

---

## 14. Verification history (preserved — not rewritten)

- Backend suite re-run after the `database.yml` + compose edits this turn:
  **`123 examples, 0 failures`** ✅.
- **Frontend `next build` — TIMEOUT EVENT (documented, not hidden):** the ad-hoc
  verification script's `npm run build` step exceeded the **400 s** tool timeout
  on this Windows host. This is recorded as a **timeout**, not a pass/fail of the
  code. Root cause: slow `next build` on the dev box, not a defect.
- **Resolution (subsequent background build):** `npm run build` was re-run in the
  background and **completed successfully**, producing
  `frontend/.next/standalone/server.js` → confirms FIX #1 (`output: "standalone"`
  in `next.config.mjs`) makes the frontend Dockerfile build correctly.
  Evidence: background run printed `BUILD_DONE` + `STANDALONE_OK`.
- Compose YAML validity + 4 healthchecks + env-driven `DATABASE_SSL` confirmed by
  scripted checks this turn.

These historical results are retained verbatim; no evidence was deleted or
re-written to make the report appear greener.

---

## 15. Final pre-deploy verdict

🟢 **Deployment files are verified and Coolify-ready** (root `docker-compose.yml`
is authoritative; services/env/volumes/ports/healthchecks/DB-init all documented;
the two real blocking bugs from the prior turn are fixed and re-verified).

🔴 **Actual deployment is NOT executed** — blocked solely by the absence of a
Coolify host/Docker in this environment. Status remains **STAGING NOT READY**
until the steps in §13 run on your Linux staging server.
