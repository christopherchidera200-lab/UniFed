# ADR-0002: Backend Topology — Modular Monolith (DDD)

- **Status:** Accepted
- **Date:** 2026-08-06

## Context

The brief mandates Ruby on Rails as the primary backend with Go for high-performance components.
Scale target is millions of users across a national federation. Two extremes were possible:
(a) microservices from day one, (b) a single undifferentiated Rails app.

## Decision

**Modular monolith** built on **Domain-Driven Design** bounded contexts, deployed as one Rails
application with strictly isolated contexts (no cross-context AR associations; contexts
communicate via the domain event bus and explicit anti-corruption layers). Go is introduced
**only** for components that justify it (e.g. ActivityPub federation fan-out, media transcoding)
and is isolated behind well-defined interfaces.

Explicit bounded contexts for M1:
- `Identity` — users, OAuth2/OIDC, MFA, roles
- `Academic` — University/Faculty/Department/Programme/Course/Session + Student/Lecturer records
- `Records` — Academic Records, transcripts, grades (Vertical Slice 1)
- `StudentId` — Digital Student ID issuance & verification (Vertical Slice 1)
- `Federation` — ActivityPub actor/activity/inbox/outbox

## Rationale

A modular monolith gives us DDD boundaries, testability, and a single deployable today, while
leaving a clean extraction path to services later (each context already owns its schema module
and event contracts). Microservices upfront would multiply operational cost with no user benefit
at ADUN's initial scale.

## Consequences

- Contexts are gems/engines under `backend/app/contexts/`.
- Cross-context calls go through `Context::Gateway` ports, never direct AR joins.
- Go federation service is a separate binary behind a gRPC/HTTP boundary.
