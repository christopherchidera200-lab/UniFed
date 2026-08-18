# UniFed Nigeria — Investor Brief

> Investment-grade overview. **Status labels are explicit: PROVEN / IMPLEMENTED / IN PILOT /
> IN DEVELOPMENT / PLANNED.** No traction is overstated. Figures are planning estimates.

## Problem
African universities run fragmented, low-quality digital experiences — a tangle of WhatsApp groups,
Moodle, and bespoke portals with no interoperability, weak identity, and poor student UX. Records
and credentials are siloed per institution; cross-university collaboration and verified graduate
outcomes are manual. NDPA 2023 raises the compliance bar.

## Solution
A **federated Digital University Operating System**: each university owns its instance and data,
yet users, content, and records interoperate across nodes over **ActivityPub**. One product unifies
academic records, digital student identity, social/connect, career, research, and campus life —
with NDPA-by-design compliance.

## Why now
- Youth bulge + mobile-first adoption across Africa.
- Sovereign-data / localization pressure favors a Nigeria-owned, federation model.
- DPI + digital-transformation agendas open grant + government channels.
- ActivityPub maturity makes federation practical today.

## Product (status-honest)
- **IMPLEMENTED:** Rails 8 modular monolith (16 bounded contexts, 44 models), Academic Records +
  Digital Student ID domains, Next.js 14 frontend (5 live tabs, real data), 3 green CI pipelines,
  Terraform AWS foundation (VPC/EKS/RDS/Redis/S3/KMS), ADR set incl. federation (ADR-0003).
- **IN DEVELOPMENT:** ADUN pilot deployment; security closure (STRIX F-04/05/06/07/11/12).
- **PLANNED:** federation worker (Go), messaging, search, career, library, events, AI, media/live,
  consortium blockchain (trust only).

## Market
~200+ Nigerian tertiary institutions, ~2–3M students (indicative); 2,000+ across Africa. Most
underserved by fragmented tooling. (Directional context, not primary TAM study.)

## Target customers
- **Economic buyer:** University (VC / Registrar / ICT Directorate).
- **End users (free):** students, lecturers, researchers.

## Business model
Institutional annual license (Starter $25–45k · Enterprise $60–110k) + Federated Network add-on +
premium modules (AI, career, research, support). Grants bridge pre-revenue. **No student-data sales.**

## Competitive advantage
Federation moat: portable student identity + cross-node interoperability no monolithic portal or
centralized social app can match. Cloud-agnostic, NDPA-by-design, OSS-friendly.

## Technology advantage
Clean DDD modular monolith with a clear path to extracted services; per-instance data ownership
(no central DB scaling penalty); ActivityPub standard (Mastodon-compatible vocabulary).

## Federation advantage
Each new node adds cross-node value → direct network effect; student identity/records travel with
the user → positive lock-in; standards compatibility → ecosystem others must join.

## Current stage
Pre-pilot / pre-revenue. M1 vertical slice built; ADUN is the designated reference node (not yet
deployed/validated).

## Admiralty University pilot
The immediate commercial-validation milestone: free pilot → paid conversion, reference + case study,
federation's first live node. **Status: IN DEVELOPMENT (not yet live).**

## Traction / evidence available (honest)
- PROVEN: 151 RSpec backend specs (0 failures), 12/12 frontend unit tests, 11/11 e2e, 3 green CI.
- PROVEN: Terraform foundation validates (fmt/validate clean).
- PROVEN: STRIX security assessment (12 findings, 5 remediated).
- NOT YET: live users, paying customers, pilot retention — the next proof points.

## Financial model (Base)
- Pilot infra ~$4.8k/yr (right-sized). Team+opex run-rate ~$313k–$622k/yr.
- Break-even ~23 universities (blended) or ~8 Enterprise.
- Pre-seed $250–400k · Seed $1.5–2.5M · Scale $6–12M.
- Detail: `docs/business/{FINANCIAL_MODEL,3_YEAR_FINANCIAL_PROJECTIONS,BREAK_EVEN_ANALYSIS}.md`.

## Funding requirement
**$250–400k pre-seed** (grant + angel) to reach ADUN pilot + 1–2 institution LOIs.

## Use of funds
45% engineering · 15% security/compliance · 8% legal/IP · 4% infra · 28% G&A/buffer.

## Roadmap
M1 slice → ADUN pilot → federation + core domains (Seed) → 10–50 universities + AI/media (Scale)
→ national/Africa federation.

## Risks
Technical (federation hardening before scale); Business (slow procurement, long sales cycles);
Financial (personnel-heavy, capital-dependent). Mitigations in `FINANCIAL_RISK_REGISTER.md`.

## Mitigation (summary)
Pilot-first de-risks revenue; right-size infra; diversify funding (grant + license); federation lowers
CAC + single-university dependence; NDPA-by-design eases compliance sales.

## Long-term vision
Africa's federated university network — every institution owns its data, every student owns a
portable identity, and the whole becomes greater than the sum of its nodes.

## Investment readiness: 35/100 (investable pre-seed/grant; not yet VC-scale)
Lowest dimensions: traction (15), team (30), legal/IP (25 — no LICENSE), pilot (30). All addressed
in the 90-day plan.
