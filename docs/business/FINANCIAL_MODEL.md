# UniFed Nigeria — Financial Model

> Consolidated model linking development, infrastructure, and operating costs to the staged
> deployment plan. All personnel and opex figures are **planning estimates** (clearly labeled);
> infrastructure figures trace to `CLOUD_COST_ANALYSIS.md`; product/feature status traces to
> `COVERAGE.md` / `CODEBASE-INVENTORY.md`. No revenue or customer figures are invented.

---

## A. Development cost build-up (one-time / annual)

Roles required (Fractional-equivalent, Nigeria + remote, USD/yr estimates):
| Role | Low | High | Notes |
|---|---|---|---|
| Senior backend (Rails) ×1.5 | $45k | $75k | federation + domains |
| Frontend (Next.js) ×1 | $30k | $50k | |
| DevOps/cloud eng ×0.5 | $25k | $45k | IaC, K8s, CI |
| Security engineer ×0.5 | $30k | $55k | STRIX gaps, NDPA |
| UI/UX designer ×0.5 | $15k | $30k | |
| QA/test engineer ×0.5 | $18k | $32k | |
| AI/ML engineer ×0.5 (Stage 2+) | $30k | $55k | |
| Product/PM ×0.5 | $25k | $45k | |
| **Annual engineering team** | **~$218k** | **~$387k** | |

Non-engineering annual:
| Category | Low | High |
|---|---|---|
| Legal/compliance (NDPA, IP, contracts) | $15k | $40k |
| Data protection officer (partial) | $10k | $25k |
| Operations / SRE on-call | $20k | $45k |
| Sales / partnerships (university) | $25k | $60k |
| Marketing / brand | $10k | $30k |
| G&A, accounting, insurance | $15k | $35k |
| **Non-eng annual** | **~$95k** | **~$235k** |

**Total annual operating cost (run-rate):**
- LEAN: **~$313k/yr** · BASE: **~$500k/yr** · LOADED: **~$622k/yr**.

## B. Infrastructure cost (annual, by stage)

From `CLOUD_COST_ANALYSIS.md`:
| Stage | Universities | Annual infra (right-sized) |
|---|---|---|
| 0 | 0 (local) | $0 |
| 1 | 1 (ADUN) | $4.8k |
| 2 | 1–3 | $11k–$18k |
| 3 | 10–20 | $72k–$144k |
| 4 | 50+ | $360k–$720k |
| 5 | National | $1.8M–$4.8M |

## C. Capital requirements by milestone

| Milestone | Purpose | Capital needed (est.) |
|---|---|---|
| Pre-seed | Finish M1 slice, ADUN pilot deploy, legal/IP, security closure | **$250k–$400k** |
| Seed | 3–5 universities, federation, core domains, team | **$1.5M–$2.5M** |
| Series A / Scale | 20–50 universities, AI, media, ops | **$6M–$12M** |

## D. Cost structure summary (Stage 1–2, BASE case)
- Personnel: ~80% of opex.
- Infrastructure: ~2–4% at pilot (rises to ~30%+ at Stage 4).
- The business is **personnel-heavy early**, **infrastructure-heavy later** — typical SaaS.

## E. Assumptions register
1. Personnel rates = Nigeria-local + remote blended; verify against actual offers.
2. Infra = af-south-1 estimate; re-quote on AWS calculator.
3. FX: NGN salaries converted at planning rate; dollar-denominated for investor view.
4. No revenue modeled here (see `3_YEAR_FINANCIAL_PROJECTIONS.md`).
5. Grant/non-dilutive funding offsets opex but is not assumed in base projections.

## F. What the model shows
- **Pilot is cheap to run (~$5k/yr infra) but expensive to build (~$313k–$622k/yr team).**
- Breakeven depends on signing institutions, not usage (see `UNIT_ECONOMICS.md`, `BREAK_EVEN_ANALYSIS.md`).
- Cloud cost only becomes material at Stage 3+; it should not constrain architecture pre-scale.
