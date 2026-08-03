# ADR 0007 — Organization target type

- **Status:** Accepted
- **Date:** 2026-08-03
- **Supersedes:** none
- **Related:** ADR 0001 (collector isolation), ADR 0005 (streaming), ADR 0006 (non-domain targets)

## Context

Phase A extended the product from a domain-only tool to support IP / email /
username targets (ADR 0006). The natural next enrichment is the **organization**:
given an organization, who owns it, who carries its network, and what Autonomous
System announces its routes? This is the link that turns a list of isolated target
findings into an ownership graph — and it reuses the same RDAP + public-DNS sources
the existing collectors already rely on.

The pipeline (validation → orchestrator → scoring → streaming) is target-type
agnostic, so adding a fifth `TargetType` again required only: a schema enum value,
a validator, one collector, registry wiring, and a frontend type addition. No
schema/orchestrator/streaming changes.

Note: the persistence layer (Phase B) was **discovered already present** — a full
`storage/` package with DynamoDB + in-memory backends wired into both endpoints in
`main.py`. So "A then B" was partly moot; B's scaffolding already existed and this
change is compatible with it (the `organization` type serialises as a plain string
in `investigation_item`).

## Decision

Add `TargetType.ORGANIZATION = "organization"`.

An organization target is **anchored to its primary domain** (e.g. `google.com`).
This keeps enrichment deterministic and lawful: it avoids fuzzy "org name → WHOIS
registrar" resolution guessing, and it reuses the exact public sources already
vetted in ADR 0006.

Add one collector:

| Collector | Types | Sources (all free, key-less, public) | Findings |
|---|---|---|---|
| `organization` | organization | RDAP domain record; DNS `A`; Team Cymru ASN-origin TXT; RDAP IP record | Organization profile (consolidated), Registrant organization, Accredited registrar, Originating Autonomous System, Network-owning organization |

The collector assembles an ownership graph:
1. **RDAP domain** → registrar (accredited) and registrant org if published.
2. **DNS `A`** → a representative IPv4 address for the org.
3. **Cymru ASN TXT** (`<ip>.origin.asn.cymru.com`) → ASN, route, country, RIR — who announces the org's net.
4. **RDAP IP** → the network-owning org (often the registrant; sometimes a carrier/cloud provider — the interesting case, surfaced as a distinct finding only when it differs).

Each layer is isolated (per-collector timeout + exception capture), so a dead RDAP
or DNS source degrades gracefully rather than failing the investigation. Network
owner is omitted when identical to the registrant to avoid duplicate noise.

## Consequences

Verified live against `google.com`: registrar `MarkMonitor Inc.`, ASN `15169`,
route `192.178.0.0/15`, country `US`, RIR `arin`, network owner `Google LLC` — all
from public sources in ~14s.

Frontend: `organization` added to `TARGET_TYPES` (radiogroup + per-type
placeholder/example/hint). No detection change — a domain still defaults to the
`domain` type; `organization` is an explicit override, matching the "we guess but
let you correct" UX.

Contract test (`openapi.snapshot.json`) regenerated to include the new enum value;
the frontend mirror (`types.ts`) mirrors it.

## Tests added

- `test_organization_collector.py` — graph assembly with mocked DNS (resolver
  monkeypatch) + RDAP (respx): registrant/registrar/ASN/network-owner; network
  owner omitted when equal to registrant; 404 domain → "No registration record";
  RDAP failure still yields ASN/network-owner findings.
- `test_target_coverage.py` / `_async.py` — org has the `organization` collector;
  streaming `started` event lists it.
- Frontend `e2e/live-org.spec.ts` — real backend, full UI→SSE→collector→score chain.

Backend **100 pytest + ruff clean**. Frontend **186 vitest + tsc clean + build OK**.

## Alternatives considered

- **Fuzzy org-name → registrar lookup.** Rejected: it requires guessing the primary
  domain from a free-text name (e.g. "Google" → `google.com`), which is error-prone
  and can silently investigate the wrong entity. Anchoring on a domain is explicit
  and auditable.
- **Enrich with staff/breach/associated-account data.** Rejected as out of scope and
  unlawful without authorization. The org graph deliberately stops at registration
  + network ownership — the same data a WHOIS/RDAP lookup returns.
- **ASN → all announced prefixes / peers.** Deferred: the single origin ASN is the
  highest-signal public fact; enumerating full prefix/peer graphs is a later phase.
