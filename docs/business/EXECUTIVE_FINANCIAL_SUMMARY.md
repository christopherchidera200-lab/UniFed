# UniFed Nigeria — Executive Financial Summary (DRAFT)

> **DRAFT — internal strategy document. Prepared by the Finance/Business Strategy/Cloud Economics
> team. NOT investment advice. All figures are model-based estimates with explicit assumptions;
> no revenue, customers, or users are fabricated. Cloud prices are indicative 2026 AWS ranges and
> MUST be re-verified against live AWS pricing before any financial commitment.**

---

## 1. One-line verdict

UniFed has a **credible, differentiated product thesis** (federated University OS over ActivityPub)
with **real, tested code** (backend + frontend + IaC) but is at **pre-revenue, pre-pilot stage**:
staging is documented but not live, and security has an open Critical item. Fund the ADUN pilot and
close the security/legal gaps before scaling spend.

## 2. What actually exists (evidence-based)

| Layer | Status | Evidence |
|---|---|---|
| Backend (Rails modular monolith, 19 contexts) | ✅ Built & tested | 36 spec files; full-suite green (233/1, the 1 pre-existing & unrelated) |
| Frontend (Next.js) | ✅ Built & tested | Vitest + Playwright green |
| Identity/Auth/OIDC/MFA/RBAC/NDPA consent | ✅ | `identity` context |
| Academic Records + Digital Student ID (signed) | ✅ | `academic`/`records`/`student_id` |
| Federation core (ActivityPub inbox/outbox/webfinger) | ⚠️ Partial | core present; F-04/05/06 hardening open |
| Social feed, Library, SIWES, Career (minimal), Catalog, Calendar, Assessment rollup | 🟡 Partial | per FEATURE-GAP-AUDIT |
| Terraform AWS foundation (VPC/EKS/RDS/Redis/S3/KMS) | 🟣 Defined, NOT deployed | `infra/terraform/main.tf` |
| Kubernetes/Helm manifests | 🟣 Defined | `infra/k8s/*` |
| CI/CD (GitHub Actions) | ✅ | backend/frontend/terraform workflows |
| Security | 🔴 Critical + Mediums (pre-remediation) | STRIX reports; Critical fixed in code, secret-set pending |
| Legal/IP docs | ✅ Draft set | `docs/legal/*` (19 DRAFTs, need lawyer) |
| Mobile (Flutter), AI platform, Live streaming, Marketplace, Research, GIS, Blockchain | 🔴 Not implemented | README "planned"; roadmap Phase 2–6 |

**Test baseline (this audit):** backend RSpec green; **ADUN pilot is the immediate commercial-validation milestone, not yet deployed.**

## 3. Staged cost picture (full detail in CLOUD_COST_ANALYSIS.md)

| Stage | Scope | Indicative annual infra (USD) |
|---|---|---|
| 0 | Local $0 dev | $0 |
| 1 | ADUN pilot (1 node, modest) | ~$9k–$18k/yr (or $0 on free tier/Coolify) |
| 2 | 1–3 unis | ~$30k–$70k/yr |
| 3 | 10–20 unis | ~$150k–$400k/yr |
| 4 | 50+ unis | ~$700k–$1.5M/yr |
| 5 | National/Africa | $2M–$5M+/yr |

*Assumption-led; see CLOUD_COST_ANALYSIS.md for the per-service build-up and alternatives.*

## 4. Business model (summary)

Primary paying customer = **the university** (institution), not the student. Students are end users.
Recommended lead model: **institutional annual subscription** (tiered by size) + optional **per-student**
component + **premium modules** (AI, analytics, career, research, federation services). Marketplace/
creator/transaction fees are **post-pilot, scale** revenue only. **Never sell student personal data.**

## 5. Readiness scores (0–100, detailed in INVESTMENT_READINESS.md)

| Dimension | Score |
|---|---|
| Product readiness | 55 |
| Technical readiness | 65 |
| Security readiness | 60 (post-remediation ~80) |
| Pilot readiness | 45 (code ready, deploy+legal+security pending) |
| Market readiness | 50 |
| Business model readiness | 55 |
| Financial model readiness | 50 |
| Legal/IP readiness | 35 |
| Data protection readiness | 40 |
| Team readiness | 40 |
| Traction readiness | 20 |
| Investment readiness | 45 |
| Grant readiness | 55 |

**Composite (weighted): ~48/100** — fundable for a **pre-seed/grant** raise with the milestone plan,
not yet for a large VC round.

## 6. Top risks (full register in FINANCIAL_RISK_REGISTER.md)

1. Cloud-cost explosion at scale (EKS + Multi-AZ RDS + NAT + data egress).
2. AI API cost explosion if AI features ship naive.
3. Slow university procurement / long sales cycles (public-sector).
4. Single-university dependence (ADUN) until federation proves out.
5. Open Critical security item + legal/IP gaps (no licence, unassigned contributions).
6. Federation complexity (interop, moderation, abuse) under-estimated.

## 7. What funding unlocks (the $0 → national arc)

- **$0 prototype** ✅ done (local, this repo).
- **~$50k–$150k** → ADUN funded pilot: secure prod infra, close security/legal, real deployment, validation.
- **~$1M–$3M seed** → 3–10 universities, engineering team, AI/security, support, partnerships.
- **~$10M+ Series A** → national/regional scale, federation network, enterprise sales, ops.

## 8. Recommended next 90 days (also in §top-10)

1. Deploy ADUN staging → pilot (close Critical secret + Mediums).
2. Execute signed University Pilot Agreement (draft exists).
3. Engage Nigerian tech lawyer; add `LICENSE` + contributor IP assignments.
4. Complete DPIA + NDPA readiness before go-live.
5. Build the financial model owner review + pricing pilot with ADUN.
6. Lock the security remediation (federation hardening F-04/05/06).
7. Define the unit-economics instrumentation (per-uni/per-student cost telemetry).
8. Pursue 1–2 aligned grants (digital education / African innovation / DPI).
9. Recruit a technical co-founder / senior engineer (team gap).
10. Produce the investor data room (this doc set + legal + security).

*This summary is a navigation aid; every claim is expanded in the companion documents.*
