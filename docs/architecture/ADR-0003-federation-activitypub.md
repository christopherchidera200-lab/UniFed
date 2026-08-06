# ADR-0003: Inter-University Federation over ActivityPub

- **Status:** Accepted
- **Date:** 2026-08-06

## Context

Each university owns its data and infrastructure but must participate in a national federation
(home feed, connect, discover across nodes). ADUN is the first node, not the owner.

## Decision

Federation uses **ActivityPub** (W3C Recommendation) with JSON-LD. Each university instance is
an Actor (`Application`/`University` actor) with `inbox`/`outbox`. Cross-node content
(home/connect/discover) flows as Activities (`Create`, `Announce`, `Follow`, `Accept`).

- Every user/group/university is a discoverable Actor with an HTTP `actor` URI.
- `outbox` is the source of truth; `inbox` receives signed (`HTTP Signatures` / `Linked Data
  Signatures`) activities from peer nodes.
- A **Go federation worker** handles delivery fan-out, retry/backoff, and signature verification
  at scale; the Rails app owns activity *modeling* and *authorization*.
- Federation is **opt-in per content type** via a federation policy per context (privacy-by-design).

## Consequences

- Deploys are independently owned; no shared database.
- Subject to the ⚠️ open question in the ADUN brief: "decentralized = blockchain creds, federated
  system, or both." ADR-0003 covers the *federated system* axis. Blockchain credential anchoring
  is a separate context (`Consortium`) deferred to a later milestone.
