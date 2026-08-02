# CloudIntel

Cloud-native OSINT aggregation SaaS. Legal, public-source intelligence in one dashboard.

## Status

| Layer | State |
|---|---|
| Backend API | Domain intelligence vertical slice (DNS, WHOIS, TLS, HTTP fingerprint, subdomains) + risk scoring. **52 tests passing.** |
| Frontend | **Phase 0** — design system, theming, typed API client, test harness. **118 unit + 17 e2e passing.** |
| Investigation UI | Not started (Phase 2) |

The landing page currently demonstrates the design system and accessibility
scaffolding. The investigation workspace replaces it in Phase 2.

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
