# ADR 0001: Serverless-first compute

## Status
Accepted

## Context
CloudIntel traffic is bursty and unpredictable: an analyst runs a scan, then nothing for an hour.
A single-tenant portfolio project cannot justify always-on ECS tasks at idle cost.

## Decision
Lambda + API Gateway HTTP API for all synchronous API traffic. FastAPI is wrapped with Mangum so
the *same* application object runs locally under uvicorn and in Lambda — zero framework drift.

Long-running collectors (subdomain enumeration over large CT datasets) go to a separate async
Lambda invoked via EventBridge/SQS, with results written to DynamoDB and polled by the client.

## Consequences
- 15-minute Lambda ceiling caps any single collector run. Enforced with a 25s per-collector timeout
  in the orchestrator so the sync path always returns inside API Gateway's 29s limit.
- Migration path to ECS/Fargate is preserved: the ASGI app is container-ready
  (`backend/Dockerfile`), so the switch is an infra change, not a rewrite.
- Cold starts mitigated with ARM64 (graviton), slim deps, and provisioned concurrency on the
  paid tiers only.
