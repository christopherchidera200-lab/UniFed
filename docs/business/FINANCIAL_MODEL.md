# UniFed Nigeria — Financial Model (DRAFT)

> **DRAFT — model-based. Assumptions explicit [F1]… All ranges; verify before use. No fabricated
> revenue. Personnel dominates; infra is a small fraction (see UNIT_ECONOMICS). Currency USD.**

---

## 1. Cost structure (annual, steady-state)

### Personnel [F1] (indicative fully-loaded, USD/yr)
| Role | Count (Seed) | $/yr | Subtotal |
|---|---|---|---|
| Backend engineers | 3 | $40k–$70k | $120k–$210k |
| Frontend engineers | 2 | $35k–$60k | $70k–$120k |
| Cloud/DevOps/SRE | 1–2 | $50k–$90k | $50k–$180k |
| Security | 0.5–1 | $60k–$110k | $30k–$110k |
| QA | 0.5–1 | $30k–$55k | $15k–$55k |
| Product/Founder | 1–2 | $0–$120k | $0–$240k |
| UI/UX | 0.5 | $30k–$55k | $15k–$55k |
| AI/ML (scale) | 0–1 | $60k–$110k | $0–$110k |
| Ops/Support | 1 | $25k–$45k | $25k–$45k |
| **Personnel total** | | | **$325k–$1.13M** |

### Non-personnel (annual)
- Cloud infra: see CLOUD_COST_ANALYSIS (Stage-dependent $9k–$5M).
- Legal/compliance/NDPA: $15k–$60k/yr (lawyer, DPIA, audits).
- Tooling/CI/registry/observability: $5k–$20k.
- Sales/marketing: $20k–$150k (travel, events, content).
- Office/overhead: $10k–$60k.
- Contingency: 10–15%.

## 2. Development cost to key milestones [F2]

| Milestone | Indicative dev cost (team×months) |
|---|---|
| ADUN funded pilot (secure deploy + security + legal) | $150k–$400k (6–12 mo, small team) |
| Multi-uni (3–10) product completeness (M2–M4) | $1M–$3M (12–24 mo) |
| National/scale readiness (M5–M7) | $5M–$12M (24–42 mo) |

[F2] assumes the Seed/Series-A team sizes above; pre-seed is leaner.

## 3. Revenue model inputs (see PRICING_STRATEGY / BUSINESS_MODEL)
- Institutional subscription anchor; per-student as tier metric; premium modules; grants.
- Conservative take-rate: pilot free → 2–3 paid unis by end Y1 → 10–20 by Y2 → 50+ by Y3.

## 4. Contribution margin
- Infra+support per uni is low vs price (UNIT_ECONOMICS: ~78% infra gross at Medium).
- **True margin** = price − (infra+support+allocated personnel+compliance). Personnel is the lever.

## 5. CAPEX vs OPEX
- **CAPEX:** minimal (software is IP; no hardware). Mainly sunk engineering time (treated as opex/
  investment). Cloud is OPEX (no capex if managed services).
- Grant-funded infra = non-dilutive opex coverage.

## 6. Cash model
- Burn ≈ personnel + infra + opex − revenue − grants.
- Pre-revenue burn dominated by personnel; see 3_YEAR projections for runway.

## 7. Sensitivity
- Worst case: pilot slips 6–12 mo → +$150k–$400k burn, no revenue.
- AI cost runaway: add $50k–$500k/yr if unmetered (mitigate with guards).
- Egress at scale: +20–40% infra if federation traffic high.

*Full projections: 3_YEAR_FINANCIAL_PROJECTIONS.md. Break-even: BREAK_EVEN_ANALYSIS.md.*
