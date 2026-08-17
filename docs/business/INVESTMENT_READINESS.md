# UniFed Nigeria — Investment Readiness (DRAFT)

> **DRAFT — due-diligence scorecard (0–100). Scores reflect repo evidence this audit. No inflated
> traction. See companion docs for basis.**

---

## 1. Readiness scorecard

| Dimension | Score | Basis / gap |
|---|---|---|
| Product readiness | **55** | M1 done, tested; many modules partial/missing (FEATURE-GAP-AUDIT) |
| Technical readiness | **65** | Solid Rails monolith + IaC; no live deploy yet |
| Security readiness | **60** (post-fix ~80) | Critical fixed in code; secret-set + Mediums + federation hardening pending (STRIX) |
| Pilot readiness | **45** | Code ready; deploy + legal + security + signed agreement pending |
| Market readiness | **50** | Clear need, no live validation; procurement slow |
| Business model readiness | **55** | Model defined; pricing unvalidated; no WTP data |
| Financial model readiness | **50** | Model built (this set); telemetry missing; ranges only |
| Legal/IP readiness | **35** | **No LICENSE, unassigned personal contributions, no entity confirmed** (IP-OWNERSHIP-AUDIT) |
| Data protection readiness | **40** | Drafts exist; **DPIA not done**; consent versioning done; deletion/export missing |
| Team readiness | **40** | Thin team; key-person risk; no proven co-founder/eng lead |
| Traction readiness | **20** | ADUN relationship, not a live paid deployment; no users in production |
| Investment readiness | **45** | Pre-seed/grant fundable; not Series-A ready |
| Grant readiness | **55** | Strong thematic fit; blocked by legal/DPIA/signed-agreement gaps |

**Composite (unweighted avg): ~49/100.** Weighted toward execution/gaps ≈ **48**.

## 2. What's missing before each funding type

### A. Grants
- LICENSE + IP assignments; DPIA; signed ADUN agreement; live pilot; impact framework.
- *(See GRANT_READINESS, FUNDING_STRATEGY.)*

### B. Angel investors
- Live ADUN pilot + basic traction metrics; clear lead use-of-funds; founder commit.
- Legal entity + cap table basics; IP assigned.

### C. Venture capital (Seed)
- 2–3 paid unis OR strong pilot + pipeline; team expanded (senior eng/co-founder);
- security closed; unit economics telemetry; defensible federation moat demonstrated.

### D. Strategic investors
- Federation/education synergies; ADUN + 1–2 unis live; clear enterprise motion.

### E. Government funding
- Compliance/localisation; TETFund/NITDA alignment; procurement readiness; impact metrics.

### F. University partnerships
- Signed pilot agreement; DPIA; security closure; onboarding kit; WTP pricing pilot.

## 3. Prioritized funding-readiness roadmap (90 days)
1. Close security Critical + Mediums; verify in prod-like env.
2. Add `LICENSE` + contributor IP assignments; form/confirm entity.
3. Complete DPIA + NDPA readiness before go-live.
4. Sign ADUN pilot agreement; deploy pilot (Coolify/EC2).
5. Recruit senior engineer / technical co-founder (team gap).
6. Instrument unit-economics telemetry (per-uni/per-student cost).
7. Run ADUN pricing/WTP pilot; lock ranges.
8. Harden federation (F-04/05/06) before broad federation.
9. Build impact-measurement framework (for grants).
10. Assemble investor data room (this doc set + legal + security + financials).

## 4. Investment thesis (objective)
**Investable as a pre-seed/grant opportunity** with a clear, differentiated federation thesis and
real code — **conditional** on closing security, legal/IP, DPIA, and a live ADUN pilot. **Not yet**
Series-A ready (traction, team, scale proof required).

*See EXECUTIVE_FINANCIAL_SUMMARY (verdict), FUNDING_STRATEGY, GRANT_READINESS, FINANCIAL_RISK_REGISTER.*
