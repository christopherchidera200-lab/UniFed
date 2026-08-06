# ADR-0001: Platform Constitution & Repo Strategy

- **Status:** Accepted
- **Date:** 2026-08-06
- **Deciders:** Founder (C. Chidera), CTO (UniFed Engineering Org)

## Context

UniFed Nigeria is being built as the Digital University Operating System, first deployed at
Admiralty University of Nigeria (ADUN) and federated to other universities over ActivityPub.
The GitHub repo `christopherchidera200-lab/UniFed.git` was previously used to hold an unrelated
investigation-platform (CloudIntel) prototype.

## Decision

1. `UniFed.git` is the **single canonical repository** for the UniFed platform.
2. The prior CloudIntel code is **archived** as the `cloudintel-archive` branch (never deleted)
   and remains available in its own `CloudIntel.git` remote. Nothing is destroyed.
3. Development is **incremental vertical slices**, not big-bang. Milestone M1 = Foundation +
   Vertical Slice 1 (Academic Records + Digital Student ID).
4. Every major milestone requires **Founder approval** before merge to `main`/`master`.

## Consequences

- `master` now hosts the UniFed platform from scratch.
- Historical CloudIntel work is recoverable.
- We avoid the "25-module megaproject that never ships" failure mode by shipping thin, deep slices.
