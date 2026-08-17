# UniFed Nigeria — Investor Brief (DRAFT)

> **DRAFT — investor-ready. Status labels used honestly: PROVEN / IMPLEMENTED / IN PILOT / IN
> DEVELOPMENT / PLANNED. No exaggerated traction. Basis: repository audit (this session).**

---

## 1. Problem
Nigerian/African universities run **fragmented, low-UX tooling** — disjointed portals, LMS, social
groups, manual records, and separate career offices. Students and staff juggle many silos;
universities lack a coherent, sovereign digital operating system, and cross-university collaboration
is nearly impossible.

## 2. Solution
**UniFed — a federated Digital University Operating System.** One product uniting digital student
identity, academic records, social, library, careers, events, research, and more — where **each
university runs its own independent instance and owns its data**, connecting to others over
**ActivityPub federation**. Data sovereignty (NDPA-aligned) by design.

## 3. Why now
- Mobile-first, large youth population; demand for consumer-grade campus UX.
- Government digital-transformation + grant funding (TETFund/NITDA/DPI themes).
- No dominant "University OS + federation" in the region; ActivityPub is proven (Mastodon) but
  unused in higher ed → first-mover window.

## 4. Product (honest status)
- **IMPLEMENTED & tested:** Rails modular-monolith backend (19 contexts), Next.js frontend, OIDC/MFA/
  RBAC, NDPA consent ledger (with versioning), academic records + **signed digital student ID &
  transcripts**, social feed, library, SIWES, career (minimal), catalog/search (PG ILIKE), calendar,
  assessment rollup, ActivityPub federation **core**.
- **IN PILOT (not live):** ADUN (`adun.unifed.ng`) reference node — code ready, staging documented,
  deployment pending.
- **IN DEVELOPMENT:** federation hardening (F-04/05/06), admin portal, research, LMS/assignments.
- **PLANNED:** mobile (Flutter), AI platform, Live streaming, Marketplace, Creator economy, GIS,
  blockchain credential anchoring.

## 5. Market
~200+ Nigerian universities (public denominator) + West Africa. TAM = African HE; SAM = Nigerian
(unis wanting integrated sovereign OS); SOM = ADUN → 3–10 → 50+ . *Directional; commission a market
study before quoting TAM/SAM/SOM precisely.*

## 6. Target customers
- **Paying customer / economic buyer:** the **university** (ICT/VC/procurement).
- **End user:** students/staff (free at point of use).
- **Secondary:** govt/grantmakers, consortia.

## 7. Business model
Tiered **institutional annual subscription** (anchor) + per-student as tier metric + **premium modules**
(AI, analytics, career/employer, research, federation) + implementation/support + **grants**
(non-dilutive). **Never sell student personal data.**

## 8. Competitive advantage
- **Federation + sovereignty:** unis own data, yet gain network effects (different from a portal or
  a centralised LMS).
- **Integrated OS** vs bolted-together tools.
- **Signed verifiable credentials** (transcripts/ID).
- **Local academic model** (ADUN ADR) + OSS/portable IaC.

## 9. Technology advantage
Rails modular monolith (fast feature velocity) + Go federation workers (scale) + Terraform/EKS IaC
(portable) + ActivityPub (open standard, Mastodon-compatible vocabulary planned). Security-first
(STRIX remediation; fail-closed auth).

## 10. Federation advantage
Each new university adds cross-instance people/content → **network effects without central data
ownership** → defensible moat + easier adoption (sovereignty).

## 11. Current stage
**Pre-revenue, pre-pilot.** M1 complete & tested; staging documented not live; security Critical
fixed in code (secret-set pending); legal/IP docs drafted (licence + assignments missing).

## 12. Admiralty University pilot
ADUN is the **first reference node** (`adun.unifed.ng`). Pilot agreement **drafted**; deployment
runbook written; **not yet live**. This is the immediate commercial-validation milestone.

## 13. Traction / evidence available (honest)
- **PROVEN:** working, tested codebase (backend RSpec green; frontend Vitest/Playwright green);
  19 contexts; IaC; CI; security test report.
- **IN PILOT:** ADUN (code + docs), not production traffic.
- **NOT claimed:** paying customers, live users, revenue — none exist yet.

## 14. Financial model (summary)
Infra margin healthy (~78% at Medium uni); business is **personnel-leveraged**. Pre-revenue through
Y3 in all scenarios; break-even ~40–80 paid unis on pure subscription, ~30–50 with premium+grants
(see projections). Indicative 3-yr cumulative need ~$3.3M–$4.1M (grants offset). *Ranges; verify.*

## 15. Funding requirement
- **Pre-seed / grant:** ~$0.5M–$1.5M → ADUN funded pilot + security/legal + small team + early unis.
- **Seed:** ~$1M–$3M → 3–10 unis, team, AI/security, support, partnerships.
- **Series A:** ~$10M+ → national/regional scale, federation network, enterprise sales, ops.

## 16. Use of funds
Personnel (engineering/DevOps/security) · secure cloud infra · security remediation & audits ·
legal/IP/DPIA · ADUN pilot deployment & onboarding · product completion (M2–M4) · early sales/
partnerships · observability/telemetry.

## 17. Roadmap
M1 ✅ → M2 Federation/Social → M3 Connect/Comms → M4 Live/Media → M5 Careers/Market/Research →
M6 Admin/Wellbeing/SmartCampus → M7 AI/Blockchain/Scale (per 12–18-month roadmap).

## 18. Risks (top, with mitigation)
- **Security Critical in prod** → set secrets, verify (mitigated in code).
- **Single-uni dependence (ADUN)** → parallel pipeline + federation effects.
- **Slow procurement** → free pilot + grants + reference expansion.
- **Cloud/AI cost** → right-size architecture, token guards (ARCHITECTURE_COST_DECISIONS).
- **Legal/IP gap** → LICENSE + assignments + lawyer.
- **Team thin** → recruit senior eng/co-founder.

## 19. Long-term vision
A **federated national (then African) Digital University OS** where every university owns its data
yet participates in one interoperable academic + social + career network — public infrastructure for
higher education.

---

*Reserve the right to update status labels as the pilot goes live. Companion docs in docs/business/*
