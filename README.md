# CloudIntel

Cloud-native OSINT aggregation SaaS. Legal, public-source intelligence in one dashboard.

## Status

| Layer | State |
|---|---|
| Backend API | Domain intelligence vertical slice (DNS, WHOIS, TLS, HTTP fingerprint, subdomains) + risk scoring, blocking **and** streaming endpoints. **72 tests passing.** |
| Frontend | Design system, theming, typed API client, SSE client. **186 unit passing.** |
| Investigation UI | **Phase 1 complete** — streaming workspace at `/investigate`. **33 e2e passing** (Chromium, WebKit, mobile Safari). |

## Streaming

Investigation latency is set by the slowest third-party source. Measured against
`github.com`, four collectors finished within 4s while Certificate Transparency
burned its full 15s timeout — so the blocking endpoint made every result wait 15s.

`POST /investigations/stream` emits each collector's result as it settles:

| Event | Arrival (streaming) | Blocking |
|---|---|---|
| `tls` ok | 2.9s | 15.0s |
| `dns` ok | 3.2s | 15.0s |
| `http` ok | 4.1s | 15.0s |
| `whois` ok | 9.2s | 15.0s |
| `complete` | 17.1s | 15.0s |

Time to first intelligence: **15.0s → 2.9s**. Total wall-clock is unchanged; this
trades one long wait for progressive disclosure. See
[ADR 0005](docs/adr/0005-streaming-investigations.md).

> **Infrastructure note:** response buffering must be disabled on
> `/investigations/stream`. The app sets `X-Accel-Buffering: no`, but a proxy that
> buffers anyway silently degrades streaming back into a slow blocking request.

## Repo layout

```
backend/      FastAPI app (Mangum-wrapped for Lambda), collectors, scoring, storage
frontend/     Next.js 15 App Router dashboard
infra/        Terraform — owned by the infrastructure team, not by this codebase
.github/      CI/CD pipelines
docs/         ADRs, legal/ethics policy
```

## Quickstart

### Backend

```bash
cd backend
uv venv && source .venv/Scripts/activate   # .venv/bin/activate on macOS/Linux
uv pip install -e ".[dev]"
uvicorn app.main:app --reload --port 8000
# API docs: http://localhost:8000/docs
```

### Frontend

```bash
cd frontend
npm install
cp .env.example .env.local     # point NEXT_PUBLIC_API_BASE_URL at the backend
npm run dev                    # http://localhost:3000
```

## Verification

Every gate below is expected to pass before a change is considered complete.

```bash
# Backend
cd backend && pytest -q && ruff check .

# Frontend
cd frontend
npm run typecheck     # tsc --noEmit, strict
npm test              # vitest — unit, contract and accessibility suites
npm run test:e2e      # playwright — Chromium + mobile Safari
npm run build         # production build
npm audit             # must be free of high/critical findings
```

Current results: backend 52 passed · frontend 118 unit passed · 17 e2e passed
(1 platform-skipped) · 0 vulnerabilities.

### Regenerating the API contract snapshot

The frontend's TypeScript types are pinned to the backend's OpenAPI document. After
an intentional backend schema change:

```bash
cd backend && source .venv/Scripts/activate
python -c "import json; from app.main import app; \
  print(json.dumps(app.openapi(), indent=2, sort_keys=True))" \
  > ../frontend/src/lib/api/__tests__/openapi.snapshot.json
```

`frontend/src/lib/api/types.ts` must then be updated to match, or
`contract.test.ts` will fail — which is the point.

## Architecture

Decision records live in `docs/adr/`:

- `0001` Serverless-first
- `0002` DynamoDB single-table design
- `0003` Frontend architecture
- `0004` Dependency security posture

Two properties are worth calling out because they are enforced mechanically
rather than by convention:

**Legality is a type, not a promise.** Every `Collector` must declare a
`legal_basis`, and every `Finding` carries one as a required field. A source that
cannot state why it is lawful cannot produce a finding. A contract test asserts
this stays true.

**Accessibility is a test, not a review.** All design tokens are asserted against
their WCAG thresholds in both themes (33 assertions). A contrast regression fails
CI rather than reaching users.

## Legal boundary

Only public data and authorized APIs. See `docs/LEGAL_AND_ETHICS.md`. No credential
stuffing, no breach-dump resale, no scraping in violation of ToS, no unauthenticated
port scanning. Private, loopback, link-local and reserved address space is rejected
at the validation layer (`backend/app/validation.py`).
