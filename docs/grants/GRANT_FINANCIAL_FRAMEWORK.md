# UniFed Nigeria — Grant Financial Framework (DRAFT)

> **DRAFT — budgeting framework for grant proposals. Categories + what funding pays for + utilisation
> governance. No fabricated grant programmes. Pairs with FUNDING_STRATEGY.md / GRANT_READINESS.md.**

---

## 1. Purpose
Provide a defensible, auditable budget structure for grant applications across themes (digital
education, DPI, African innovation, cybersecurity, AI, research, entrepreneurship). Shows funders
exactly what their money buys and how it is tracked.

## 2. Budget categories

| # | Category | What it pays for | Typical % of grant |
|---|---|---|---|
| 1 | **Development** | Backend/frontend eng, federation hardening, feature completion (M2–M4) | 35–50% |
| 2 | **Infrastructure** | Cloud (per CLOUD_COST_ANALYSIS Stage 1–2), CI, registry, observability | 10–20% |
| 3 | **Security** | STRIX remediation, audits, pen-test, NDPA tooling | 5–10% |
| 4 | **AI** | AI platform (Phase 6), guards, evaluation (only if AI-themed grant) | 0–15% |
| 5 | **GIS** | Smart Campus / PostGIS (if geospatial-themed) | 0–8% |
| 6 | **Research** | Research hub build + datasets (if research-themed) | 0–12% |
| 7 | **University deployment** | ADUN pilot + onboarding kit + SSO/integration + training | 8–15% |
| 8 | **Training** | University staff/student training, admin enablement | 3–8% |
| 9 | **Operations** | PM, grants manager, support, QA, compliance | 8–15% |
| 10 | **Legal/Compliance** | LICENSE, IP assignments, DPIA, lawyer review | 2–5% |
| 11 | **Monitoring/Evaluation** | Impact framework, metrics, reporting to funder | 3–6% |
| 12 | **Contingency** | 10% reserve | 10% |

## 3. Recommended grant utilisation framework (governance)
- **Budget lines mapped to milestones** (M1–M7 roadmap) — funder sees delivery linkage.
- **CapEx vs OPEX tracked separately** (mostly OPEX; cloud = OPEX; engineering = opex/investment).
- **Per-activity cost telemetry** (build before drawdown — see UNIT_ECONOMICS instrumentation).
- **Quarterly utilisation report** vs plan; variance >10% flagged.
- **Audit trail** (UniFed consent + audit-log infra can underpin this).
- **Non-dilutive ring-fence:** grant funds ≠ equity; reported separately to investors.
- **Outcome indicators** (from impact framework): unis deployed, students served, records verified,
  careers placed, federation links, security findings closed.

## 4. Example allocation (illustrative $500k digital-education grant)
| Category | Amount |
|---|---|
| Development (M2–M3) | $200k |
| Infrastructure (Stage 1–2, 18 mo) | $60k |
| Security (STRIX closure + audit) | $40k |
| University deployment (ADUN + 2) | $60k |
| Training | $25k |
| Operations (PM/QA/compliance) | $55k |
| Legal/Compliance (LICENSE/DPIA) | $15k |
| M&E | $20k |
| Contingency (10%) | $25k |
| **Total** | **$500k** |

*Illustrative only; size to the actual programme. Verify all cloud/eng rates locally.*

## 5. Readiness to use this framework
- ✅ Budget categories defined; cost models exist (FINANCIAL_MODEL, CLOUD_COST_ANALYSIS).
- 🟡 Need: impact-measurement framework; per-activity telemetry; grants owner.
- ❌ Blockers: LICENSE/IP assignments; DPIA; signed ADUN agreement; live pilot.

*See FUNDING_STRATEGY.md (categories), GRANT_READINESS.md (scorecard), INVESTMENT_READINESS.md.*
