# UniFed Nigeria — Investment Readiness Assessment

> Scored 0–100 from repository evidence (this audit). Low scores are **gaps to close before raise**,
> not verdicts. See `docs/security/STRIX-*`, `docs/legal/*`, `docs/compliance/*`, `CODEBASE-INVENTORY.md`.

## Scores
| Dimension | Score | Evidence / gap |
|---|---:|---|
| Product readiness | 35 | 2/13+ domains built; M1 slice + ADUN pilot pending |
| Technical readiness | 60 | Clean DDD monolith, 151 RSpec, 12/12 FE tests, IaC; federation 0% |
| Security readiness | 45 | STRIX 5/12 fixed; F-07/11/12 open (secrets/config); no MFA/OIDC impl |
| Pilot readiness | 30 | ADUN is reference node but not yet deployed/validated |
| Market readiness | 55 | Clear need, no WTP proof, no references |
| Business model readiness | 65 | Coherent model + pricing + unit econ documented |
| Financial model readiness | 70 | Staged model, projections, breakeven done |
| Legal/IP readiness | 25 | **No LICENSE file**; IP assignment drafts only; due-diligence blocker |
| Data protection readiness | 40 | NDPA-aware design; DPIA/consent drafts; not operationalized |
| Team readiness | 30 | Single founder; no committed engineering/security hires |
| Traction readiness | 15 | No live users, no paying customers, no pilot yet |
| Investment readiness | 35 | Strong docs, weak proof points + team + legal |
| Grant readiness | 55 | Strong thematic fit; needs LICENSE + budget + evidence pack |

**Composite (weighted, investor-view): ~42/100** — *fundable for pre-seed/grants on team + vision +
docs, not yet for VC scale.*

## What's missing before each funding type
- **Grants:** LICENSE file, formal budget, evidence pack, registered entity. → `GRANT_READINESS.md`
- **Angels:** pilot traction + founding team add (CTO/eng lead), clean cap table.
- **VC:** pilot + 2–3 institutions + security closure + team + metrics.
- **Strategic:** distribution rationale (telecom/EdTech/cloud) + pilot.
- **Govt:** ministry alignment + compliance + reference deployment.
- **University partnerships:** live ADUN pilot + NDPA evidence + SSO/ICT integration.

## Prioritized readiness roadmap
1. **ADUN pilot deploy + 90-day retention/engagement data** (biggest de-risk).
2. **LICENSE file + IP assignment execution** (unblocks OSS grants + diligence).
3. **Close STRIX F-07/11/12** (secrets/config) + implement MFA/OIDC.
4. **Add 1–2 committed senior eng/security hires** (team risk).
5. **Formal entity + cap table + data-room** (investor hygiene).
6. **Reference customers / LOIs** from 2–3 universities.
7. **NDPA operationalization** (DPIA sign-off, consent, DSR procedure).
