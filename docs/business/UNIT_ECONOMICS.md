# UniFed Nigeria — Unit Economics

> **Evidence basis:** infrastructure costs derived from `CLOUD_COST_ANALYSIS.md` (right-sized
> pilot ≈ $400/mo/university at Stage 1–2). Personnel, support, and onboarding are **estimates**
> labeled as such. No student/revenue figures are invented — real usage does not yet exist
> (product is pre-pilot). All ranges are realistic planning estimates, not commitments.

---

## 1. Cost to serve ONE university (annual)

| Cost type | Fixed (annual) | Variable (per active student/yr) | Notes |
|---|---|---|---|
| Infrastructure (right-sized) | $4.8k | — | ~$400/mo from cloud analysis |
| Platform support (shared SRE) | $3.0k | — | amortized across portfolio |
| Onboarding & integration | $5.0k (one-time) | — | SSO/ICT, data import, training |
| Account management | $2.0k | — | per-uni success |
| **Total annual / university** | **~$14.8k** | see below | excl. one-time onboarding |

**Marginal cost of adding a university** (incremental, no new headcount):
- Infrastructure only: **~$4.8k/yr** (shared control plane amortizes).
- With onboarding: **~$9.8k one-time + $4.8k/yr**.

## 2. Cost to serve ONE active student (annual, variable)

Assumptions (clearly labeled):
- Active student = logs in ≥1×/month.
- Storage: 50 MB (profile, docs, avatars) LOW / 200 MB MEDIUM / 1 GB HIGH.
- Bandwidth: 0.5 GB LOW / 3 GB MEDIUM / 10 GB HIGH per month.
- S3 storage $0.023/GB-mo; egress $0.09/GB (af-south estimate).

| Scenario | Storage/yr | Bandwidth/yr | Infra variable | Support alloc | **Cost/student/yr** |
|---|---|---|---|---|---|
| LOW | $0.01 | $0.54 | $0.55 | $0.30 | **~$0.85** |
| MEDIUM | $0.06 | $3.24 | $3.30 | $0.50 | **~$3.80** |
| HIGH | $0.28 | $10.80 | $11.08 | $0.80 | **~$11.90** |

**Infrastructure cost per active student is < $12/yr even at HIGH usage** — extremely favorable.
The dominant cost is **fixed platform + personnel**, not per-student variable cost.

## 3. Fixed vs variable split (single university)

| | Annual | Share |
|---|---|---|
| Fixed (infra base + support + AM) | ~$10k | ~68% |
| Variable (per-student) | ~$0.85–$11.90 × active students | ~32% (at 5k students, MEDIUM) |

UniFed is a **high-fixed, low-variable** business → strong gross margin once universities are signed.
Breakeven is driven by **universities (B2B contracts)**, not by student count.

## 4. Gross margin model (illustrative, MEDIUM usage)

- Cost to serve 1 university (5,000 active students, MEDIUM): $14.8k fixed + (5,000 × $3.80) = **$33.8k/yr**.
- If priced at **$40k/yr** institutional license → gross margin ≈ **15%** (thin; needs scale or higher price).
- At **$60k/yr** → gross margin ≈ **44%**.
- At **$90k/yr** (Enterprise tier) → gross margin ≈ **62%**.

> The lever is **price per university**, not student count. Per-student pricing is a secondary
> model (see `PRICING_STRATEGY.md`).

## 5. Marginal cost summary
- **Add a student:** $0.85–$11.90/yr (negligible).
- **Add a university:** ~$4.8k/yr infra + ~$9.8k one-time onboarding.
- **Add a federation node:** near-zero incremental (ActivityPub is peer-to-peer; no central DB).

## 6. Sensitivity
- If media/video (UniFed Live) ships, HIGH bandwidth scenario dominates → cap via CDN + per-uni
  media budgets.
- If AI premium launches, add $0.50–$3.00/active-user/yr in API consumption (Stage 2+ only).

---

## Key takeaway
UniFed's unit economics are **structurally sound**: near-zero marginal student cost, favorable
storage/bandwidth, and a federation model with no central-database scaling penalty. The financial
risk is **fixed platform cost + slow university procurement**, not per-user cost. Pricing must
anchor on the institutional license, not per-student.
