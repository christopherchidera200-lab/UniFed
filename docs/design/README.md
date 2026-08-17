# UniFed Nigeria — Frontend Design (DRAFT)

> **DRAFT — design system response to the "Frontend Design Brief for Hermes".**
> Grounded in the **actual UniFed frontend** (Next.js Pages Router; `frontend/src/design/tokens.ts`
> = institutional navy + saffron, DM Sans), not the Mastodon screenshots (used only for IA).

## Artifact (primary deliverable)
- **`UniFed-Frontend-Design-Lab.html`** — self-contained component lab with all five requested sections:
  1. **IA diagram** — routes → primary nav + bottom tab bar + in-section tabs.
  2. **Color & typography** — base palette (real tokens) + per-content-type accents + role/federation colors.
  3. **Component specs** — federation badge, content cards (one variant per type), live-data profile card, notification row, permission-gated nav drawer, session-status affordance.
  4. **Mobile-first layouts** — Home/Campus Feed, Assignments (role-gated), Research, Admin (role-gated), bottom tab bar.
  5. **Rationale** — one paragraph per deviation from the Mastodon reference.

Open the HTML in a browser to inspect the live components.

## Source-verified corrections (important — read before implementation)
The brief cited three "known issues." Audited against the repo at `compliance/readiness` HEAD:

| Brief claim | Verdict | Evidence |
|-------------|---------|----------|
| Profile cards aren't live | **NOT REPRODUCED** | `profile.tsx` binds `useQuery(['profile']) → unifedApi.profile(token)`; renders real fields |
| Admin nav not permission-gated | **ALREADY ENFORCED** | Admin link shows only if `actor_type === "admin"` (`profile.tsx:117`) + `RequireAuth` + server `admin:users` |
| Token auto-refresh gap | **CONFIRMED REAL** | `auth.ts` stores `refresh_token` but never calls it; no expiry/refresh logic |

Also: the brief assumed `/campus /assignments /research /admin` as primary tabs, but the real
`tokens.nav` is Home/Connect/Create/Discover/Profile. Resolved via a permission-gated slide-out
drawer (see IA section).

## Status
- Design: DRAFT for review.
- Implementation: NOT started (await direction). Specs are ready to build in `frontend/src/components/`.
- Backend dependency: the session toast (§3.6) needs the `auth.ts` refresh-token call implemented.

## Next
1. Confirm palette / IA direction.
2. Implement `FederationBadge`, `ContentCard` (variants), `ProfileCard` (live), `NavDrawer` (gated), `SessionToast` in `frontend/src/components/`.
3. Wire `/admin` entry to the drawer (already role-gated in code).
4. Implement refresh-token logic in `auth.ts` to back the session affordance.
