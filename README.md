# CloudIntel

Cloud-native OSINT aggregation SaaS. Legal, public-source intelligence in one dashboard.

## Status
Vertical slice: **Domain Intelligence** (DNS + WHOIS + TLS + tech fingerprint + risk score) running
end-to-end on the production architecture (FastAPI -> Lambda -> API Gateway -> DynamoDB/S3).

## Repo layout
```
backend/      FastAPI app (Mangum-wrapped for Lambda), collectors, scoring, storage
frontend/     Next.js 15 App Router dashboard
infra/        Terraform (modular: network-free serverless core)
.github/      CI/CD pipelines
docs/         ADRs, runbooks, legal/ethics policy
```

## Quickstart (local)
```bash
cd backend
uv venv && source .venv/Scripts/activate
uv pip install -e ".[dev]"
uvicorn app.main:app --reload --port 8000
# http://localhost:8000/docs
```

```bash
cd frontend
npm install
npm run dev   # http://localhost:3000
```

## Legal boundary
Only public data and authorized APIs. See `docs/LEGAL_AND_ETHICS.md`. No credential stuffing,
no breach-dump resale, no scraping in violation of ToS, no unauthenticated port scanning.
