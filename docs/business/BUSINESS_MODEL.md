# UniFed Nigeria — Business Model (DRAFT)

> **DRAFT — strategy document. No revenue/users/customers fabricated. Assumptions labelled.**
> Companion to BUSINESS_MODEL_CANVAS.md, UNIT_ECONOMICS.md, PRICING_STRATEGY.md.

---

## 1. Core principle: who pays vs who uses

- **End user:** the student (and staff/lecturer). They use UniFed free at point of use.
- **Economic buyer / paying customer:** the **university** (institution), which licenses the platform
  for its community. This is the dominant HE SaaS pattern in Nigeria/Africa (the institution holds the
  budget, the procurement relationship, and the data-controller obligation under NDPA).

This separation is deliberate and defensible: selling to institutions gets you annual, budgeted,
multi-year contracts; monetising students directly (ads, data) conflicts with the NDPA/privacy thesis
and the "unis own their data" federation model.

## 2. Revenue streams — evaluated

| # | Model | Verdict | Rationale |
|---|---|---|---|
| 1 | University SaaS licensing (annual) | ✅ **Lead** | Budgeted, renewable, fits public-sector procurement |
| 2 | Per-student pricing | 🟡 Complementary | Use as a tier metric, not sole basis (public unis cap student fees) |
| 3 | Institutional annual subscription (tiered) | ✅ **Lead** | Tiered by size/features; simplest to sell |
| 4 | Enterprise deployment (on-prem/own-cloud) | 🟡 Later | Large/regulated unis; higher ACV, higher delivery cost |
| 5 | Premium university services | ✅ | AI, analytics, advanced moderation, SSO/integration |
| 6 | Career/employer partnerships | 🟡 Post-pilot | Employers pay for access to vetted talent; needs critical mass |
| 7 | Marketplace transaction fees | 🔴 Scale-only | Requires marketplace build + payments; not yet implemented |
| 8 | Creator economy revenue | 🔴 Scale-only | Not implemented; future |
| 9 | AI premium services | 🟡 Post-pilot | Per-seat or usage; cost-controlled (see FINANCIAL_RISK_REGISTER) |
| 10 | Research collaboration services | 🟡 Later | Research Hub not built |
| 11 | Employer recruitment services | 🟡 Post-pilot | Depends on career network effects |
| 12 | Sponsored opportunities | 🟡 Carefully | Must be NDPA-compliant, non-intrusive, opt-in |
| 13 | Govt/institutional contracts | ✅ | TETFund, NITDA, ministry EdTech programmes |
| 14 | Ethical data services | 🟡 Strict | **Only** anonymised/aggregated, consented, never personal-data sale |
| 15 | White-label deployments | 🟡 Later | For consortia/regional bodies |
| 16 | Implementation/support | ✅ | One-off + recurring support retainers |
| 17 | **Grants (non-dilutive)** | ✅ | Digital-education / African-innovation / DPI / cybersecurity |

**Inappropriate / risky:** selling or sharing student personal data (NDPA violation + trust breach);
intrusive ad-targeting of minors/students; opaque data use.

## 3. Recommended initial business model

**Tiered institutional subscription** as the anchor:
- **Pilot** (ADUN): heavily subsidised / free for validation (1 node, core modules).
- **Starter** (small/state unis): fixed annual fee, core modules, capped users.
- **Enterprise** (large/federal unis): annual fee + premium modules + SLA + integrations.
- **Premium add-ons** (cross all tiers): AI assistant, advanced analytics, career/employer network,
  federation network services, white-glove support.
- **Federation network fee** (scale): for unis that want managed cross-instance services.

Per-student is used only as a **fairness/tier metric** (e.g., Starter capped at N students), never as
the primary billing shock.

## 4. Why this model fits the architecture

- Federation = each uni runs its own instance → natural per-institution contract boundary.
- Modular monolith + per-context features → clean premium-module packaging.
- NDPA consent + data-controller model → privacy-safe; no reliance on data monetisation.

## 5. Revenue readiness by stage

- **Now:** grants + ADUN pilot agreement (institutional commitment, even if subsidised).
- **Post-pilot:** 2–3 paid institutional subscriptions (Starter/Enterprise).
- **At scale:** network effects (career/employer, marketplace, federation services) become material.

*All monetary amounts in PRICING_STRATEGY.md and 3_YEAR_FINANCIAL_PROJECTIONS.md are ranges with
stated assumptions; verify locally before quoting.*
