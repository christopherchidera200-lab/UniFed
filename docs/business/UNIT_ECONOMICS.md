# UniFed Nigeria — Unit Economics (DRAFT)

> **DRAFT — model-based. Assumptions explicit [U1]… No fabricated users/revenue. Currency USD
> unless noted ₦ (indicative ₦1,500/$, verify). Verify cloud prices vs AWS before use.**

---

## 1. Definitions

- **Fixed cost (per uni):** base compute/DB/cache + account management amortised. Exists regardless
  of student count.
- **Variable cost (per student):** storage, bandwidth, compute marginal, support, AI (if used).
- **Marginal cost of a university:** ~ one node's fixed infra + onboarding.
- **Marginal cost of a student:** near-zero at platform scale (storage ~MBs, compute amortised).

## 2. Base assumptions [U1]

- [U1] Avg active student per university: **Small 5k · Medium 20k · Large 40k**.
- [U2] Storage/student: **~50 MB** (profile, docs, records, media refs) → at $0.023/GB-mo S3 ≈ $0.001/student-mo (negligible).
- [U3] Bandwidth/student: **~0.5 GB/mo** academic/social → egress $0.05/GB ≈ $0.025/student-mo.
- [U4] Compute marginal/student: amortised in node cost; treat as fixed per node.
- [U5] AI cost/active user (only if AI ships): **$0.02–$0.10/user-mo** (cached, routed) — guard required.
- [U6] Support/uni/mo: **$50–$200** (tiered).
- [U7] Onboarding/uni (one-off): **$2k–$10k** (integration, SSO, training) — amortise 12–36 mo.

## 3. Per-university infrastructure cost (Stage 2 reference)

| Uni size | Fixed infra/mo [U8] | Students | Infra/student/mo | Infra/student/yr |
|---|---|---|---|---|
| Small | $400 | 5,000 | $0.08 | $0.96 |
| Medium | $900 | 20,000 | $0.045 | $0.54 |
| Large | $1,600 | 40,000 | $0.04 | $0.48 |

[U8] Right-sized node (no EKS, single-AZ RDS, one cache). Confirms **economy of scale**: large unis
are ~2× cheaper per student than small. This shapes pricing (small unis need a floor price).

## 4. Scenarios (per active student, monthly, full platform at scale)

| Scenario | Storage $ | Bandwidth $ | AI $ | Support $/stu | **Total variable $/stu-mo** |
|---|---|---|---|---|---|
| LOW usage | 0.001 | 0.01 | 0 | 0.01 | **~$0.02** |
| MEDIUM | 0.001 | 0.025 | 0.03 | 0.02 | **~$0.08** |
| HIGH | 0.002 | 0.06 | 0.10 | 0.04 | **~$0.20** |

Fixed per-uni cost is the dominant component for small unis; variable dominates only at very high
usage + AI.

## 5. Gross margin illustration (illustrative, NOT a quote)

If a Medium uni (20k students) is priced at **$3/student-yr** (~$60k/yr) and infra+support ≈
$900×12 + $200×12 ≈ **$13.2k/yr**, gross margin on infra ≈ **78%**. Personnel/product cost is
separate (see 3_YEAR projections). The point: **infra margin is healthy; the business is
personnel-leveraged, not infra-leveraged** → scale via more unis, not per-student price hikes.

## 6. Marginal-cost conclusions

- Adding a **university** ≈ one node's fixed cost ($400–$1,600/mo) + onboarding — predictable.
- Adding a **student** ≈ cents/month — near-free; enables per-student tiering without margin risk.
- **Risk:** small unis below the fixed-cost floor are unprofitable at low price → use min-commit
  or Starter flat fee.

## 7. What to instrument (recommended)
Track real per-node and per-student: compute-hours, DB size, egress GB, AI tokens, support tickets.
Current repo has no such telemetry → build before pricing lock (see LEGAL/tech: consent + audit log
exist; add cost telemetry).

*See CLOUD_COST_ANALYSIS.md (stages), PRICING_STRATEGY.md (price ranges), 3_YEAR projections.*
