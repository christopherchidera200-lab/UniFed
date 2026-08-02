# ADR 0003 — Frontend architecture

- **Status:** Accepted
- **Date:** 2026-08-02
- **Deciders:** Software Engineering (architecture, frontend, accessibility, security)

## Context

CloudIntel needs an analyst-facing dashboard. The backend already exposes a typed
REST API (`backend/app/schemas.py`) documented via OpenAPI. The frontend must be
fast, accessible, themeable, and — critically — must not drift from the backend
contract as both sides evolve.

Infrastructure (hosting, CDN, CI/CD) is owned by a separate team, so the frontend
must be a self-contained, buildable artifact with no deploy-time assumptions.

## Decision

### Next.js App Router + TypeScript strict

Static prerendering where possible; React Server Components available for
data-heavy views later. TypeScript runs with `strict`, plus `noUncheckedIndexedAccess`
and `noUnusedLocals` — array access returning `T | undefined` has already caught
real defects in the target-detection parser.

### Design tokens as CSS custom properties, consumed by Tailwind

Tailwind reads `hsl(var(--token))` rather than hardcoded palette values. This gives:

- **One source of truth.** No component hardcodes a hex value.
- **Zero-cost theming.** Light/dark is one attribute on `<html>`; no duplicated
  `dark:` variant on every element.
- **Testable accessibility.** Because tokens are declared values, contrast can be
  asserted in CI (`src/lib/utils/__tests__/design-tokens.test.ts`).

Rejected: a CSS-in-JS runtime (adds client JS, hurts LCP) and raw Tailwind palette
colours (untestable, no theming story).

### Two border tokens, deliberately

`--border` is decorative (dividers, card edges). `--border-strong` is for
interactive control boundaries and is held at >= 3:1 against `--surface` to satisfy
WCAG 1.4.11. Forcing every divider to 3:1 would be visually crude and is not what
the criterion requires.

### Theme resolved before first paint

An inline blocking script in `layout.tsx` sets `data-theme` from localStorage or
`prefers-color-scheme` before React hydrates. The `ThemeProvider` then reads the
DOM rather than storage, so React state matches what the user already sees. This
eliminates both the flash-of-wrong-theme and the hydration mismatch.

### Layered API client

```
types.ts   wire contract (mirrors Pydantic models)
errors.ts  error taxonomy — UI branches on `kind`, never on message text
client.ts  fetch, timeout, error normalisation. Nothing else.
```

Callers never see a raw `Response` or an unhandled rejection shape. Every failure
is an `ApiError` with a `kind` and a safe `userMessage`. Server-error detail is
deliberately excluded from `userMessage` so internals cannot leak to screen.

### Contract testing against the real OpenAPI document

The TypeScript types are hand-written mirrors of Pydantic models, and hand-written
mirrors rot. `contract.test.ts` pins them to a snapshot of the live spec generated
from `app.main:app`, asserting property sets, enum parity, and endpoint coverage.
A backend schema change the frontend has not absorbed fails CI instead of shipping
as a runtime `undefined`.

The suite also asserts that `legal_basis` remains **required** on `Finding` — the
architectural guarantee that makes CloudIntel legally defensible is enforced by a
test, not by convention.

## Consequences

**Positive**

- Backend/frontend drift is caught mechanically.
- Accessibility regressions are caught mechanically (33 contrast assertions).
- Theming is one attribute flip; no per-component dark-mode maintenance.
- 111 kB First Load JS, statically prerendered.

**Negative / accepted cost**

- The OpenAPI snapshot must be regenerated after intentional backend changes.
  Mitigated by documenting the exact command in the test file header.
- Design tokens are duplicated between `globals.css` and the token test. This is
  deliberate: the test is an independent statement of intent, not a tautology
  that reads the same source it validates.

## Verification

| Gate | Result |
|---|---|
| `tsc --noEmit` | clean |
| `vitest run` | 118 passed |
| `playwright test` (Chromium + mobile Safari) | 17 passed, 1 platform-skipped |
| `next build` | success, 111 kB First Load JS |
| `npm audit` | 0 vulnerabilities |
