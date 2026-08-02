# ADR 0004 — Dependency security posture

- **Status:** Accepted
- **Date:** 2026-08-02
- **Deciders:** Software Security Engineering

## Context

The initial frontend dependency set installed clean but `npm audit` reported
**5 vulnerabilities (1 critical, 4 high)**:

| Package | Severity | Issue |
|---|---|---|
| `next@15.1.6` | critical | CVE-2025-66478 |
| `postcss@<=8.5.17` | high | XSS via unescaped `</style>`; arbitrary file read and path traversal via `sourceMappingURL` |
| `sharp@<0.35.0` | high | inherited libvips CVEs (2026-33327/33328/35590/35591) |
| `vitest@<=3.2.5` | critical | RCE when the Vitest API server is reachable from a malicious page |

## Decision

Remediate all of them before the baseline commit. A portfolio project that ships a
known-critical framework version undermines the exact competence it is meant to
demonstrate.

**`npm audit fix --force` was explicitly rejected.** It proposed downgrading to
`next@9.3.3` — a breaking, six-major-version regression — because its resolver
optimises for "no advisories" rather than "working software". Automated remediation
advice is an input to judgement, not a substitute for it.

Applied instead:

1. **`next` 15.1.6 -> 15.5.22.** Required bumping `@playwright/test` to `^1.51.1`
   in the same command, because Next 15.5 declares it as a peer. Resolving the peer
   graph properly avoided `--legacy-peer-deps`, which would have masked the conflict
   rather than fixing it.
2. **`vitest` -> `^3.2.7`**, **`postcss` -> `^8.5.18`** as direct devDependencies.
3. **`sharp` pinned via `overrides`** to `^0.35.0`, since it is transitive under Next.
4. **`postcss` override set to `$postcss`**, referencing the direct dependency.
   A literal version range here is rejected by npm with `EOVERRIDE` when it conflicts
   with a direct dependency.

## Consequences

- `npm audit` reports **0 vulnerabilities**.
- Full verification re-run after the upgrade: typecheck clean, 118 unit tests pass,
  17 e2e pass, production build succeeds. The upgrade is confirmed non-breaking by
  execution, not by assumption.
- `overrides` must be revisited when Next ships its own patched `sharp`/`postcss`
  ranges, or the pins will silently hold back legitimate upgrades.

## Standing policy

- `npm audit` must report zero **high or critical** vulnerabilities to merge.
- Never accept an automated fix that downgrades a major version without review.
- Re-run the full verification suite after any dependency change.
