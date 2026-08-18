# UniFed Nigeria — Break-Even Analysis

> Based on `UNIT_ECONOMICS.md` (cost/university) and `PRICING_STRATEGY.md` (price). Break-even is
> driven by **institutions signed**, not students. Figures are planning estimates.

---

## 1. Contribution margin per university (annual)

Cost to serve 1 university (MEDIUM, 5k active students) = **$33.8k/yr** (from unit economics).

| Price tier | Revenue | Cost | Contribution/uni |
|---|---|---|---|
| Starter ($35k) | $35k | $33.8k | **$1.2k (3.4%)** |
| Enterprise ($80k) | $80k | $33.8k | **$46.2k (58%)** |
| Blended Base ($45k) | $45k | $33.8k | **$11.2k (25%)** |

## 2. Fixed cost base to cover
Annual fixed platform + G&A (lean, excl. per-uni infra) ≈ **$250k/yr** (from `FINANCIAL_MODEL.md`).

## 3. Universities required to break even

Using **blended $45k** price, $11.2k contribution/uni:
- $250k ÷ $11.2k ≈ **23 universities** to cover fixed base (excl. onboarding one-time).
- With one-time onboarding ~$9.8k/uni, effective contribution in Year 1 ≈ $1.4k → ~**180 universities**
  if all are new in-year. Reality: contribution ramps as base is amortized → **~20–25 steady-state
  universities** is the durable break-even at Base pricing.

Using **Enterprise $80k** (58% margin, $46.2k contribution):
- $250k ÷ $46.2k ≈ **6 universities** to cover fixed base.
- Durable break-even ≈ **8–10 Enterprise universities**.

## 4. Paying students required (if per-student model)
At $2/active-student/yr and $0.85–$11.90 cost/student → contribution $–$10/student. To cover $250k
fixed at $2 price with $3.80 cost (MEDIUM) = **–$1.80/student → never breaks even on per-student
alone.** Confirms: **institutional license is mandatory**, per-student is supplementary.

## 5. Monthly / Annual recurring revenue at break-even
- Base: 23 universities × $45k = **$1.035M ARR** (break-even point).
- Enterprise-lean: 8 universities × $80k = **$640k ARR** (break-even point).

## 6. Strongest pricing strategy (verdict)
**Enterprise-anchored institutional license.** Blended Base requires ~23 universities; Enterprise
requires ~8. The federation network effect lowers CAC over time (one integration → cross-node
value), improving contribution margin post-Stage 2.

## 7. Sensitivity
- If fixed cost drops to $150k (leaner G&A), Base break-even → ~14 universities.
- If price discounts to $30k (pilot-heavy), Base break-even → ~34 universities (risky).
- Onboarding bottleneck (ICT/SSO delays) extends time-to-revenue per university by 1–3 months.
