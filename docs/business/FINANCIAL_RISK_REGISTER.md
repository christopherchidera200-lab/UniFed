# UniFed Nigeria — Financial Risk Register (DRAFT)

> **DRAFT — risk register. Each risk: likelihood/impact/mitigation. No fabricated data. Tied to
> repo evidence (STRIX, FEATURE-GAP-AUDIT, staging report).**

---

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | **Cloud-cost explosion** (EKS+Multi-AZ RDS+NAT+egress) | Med | High | Right-size (ARCHITECTURE_COST_DECISIONS); no EKS pre-3 unis; Aurora Serverless; egress budget |
| R2 | **AI API cost explosion** | Med | High | Token caps, caching, model routing, degrade gracefully; off by default |
| R3 | **Bandwidth/egress blow-up** (federation) | Med | Med | CloudFront, compression, lean payloads, egress monitoring |
| R4 | **Storage cost growth** | Low | Low | Lifecycle policies, S3-IA, media only when needed |
| R5 | **Cybersecurity cost** (incident/audit) | Med | High | STRIX remediation now; 72h NDPA plan; security in CI; pen-test pre-scale |
| R6 | **Staffing cost / key-person risk** | High | High | Hire senior eng/co-founder; document; avoid bus-factor (team readiness 40) |
| R7 | **Slow university procurement** | High | High | Pilot free/subsidised; reference→expansion; grants co-fund; multi-thread pipeline |
| R8 | **Long sales cycles** (public sector) | High | Med | Founder-led; ADUN reference; framework agreements; grantmaker channel |
| R9 | **Regulatory/NDPA cost** | Med | High | DPIA pre-pilot; consent+audit built; lawyer review (legal docs draft) |
| R10 | **Federation complexity** (interop/abuse/moderation) | Med | High | Harden F-04/05/06; federation policy; defed/moderation design (FEDERATION-POLICY) |
| R11 | **Low adoption / churn** | Med | High | UX focus; career/social hooks; institutional onboarding; WTP pricing pilot |
| R12 | **Dependence on one university (ADUN)** | High (early) | High | Multi-uni pipeline in parallel; federation network effects; don't over-customise to ADUN |
| R13 | **Grant dependence** | Med | Med | Diversify (institutional revenue + investment); grants = upside not sole plan |
| R14 | **Infra vendor lock-in (AWS)** | Low | Med | Terraform portable; abstract; multi-cloud-ready per README |
| R15 | **Security Critical unfixed in prod** | Med (if ignored) | Critical | Set strong secrets (OIDC_JWKS_PRIVATE/SECRET_KEY_BASE); fail-closed done; verify before pilot |
| R16 | **Legal/IP gap** (no licence, unassigned contrib) | High | High | Add LICENSE + contributor IP assignments; lawyer (IP-OWNERSHIP-AUDIT) |
| R17 | **Data-protection gap** (DPIA not done) | High (pre-pilot) | High | Complete DPIA; retention/DSR/breach docs draft exist; operationalise |

## Top 3 to act on now
1. **R15** — set prod secrets + verify Critical closed before any pilot traffic.
2. **R16** — licence + IP assignments (blocks investment/grants).
3. **R7/R12** — de-risk single-uni dependence via parallel pipeline + grants.

*See FUNDING_STRATEGY, INVESTMENT_READINESS, GRANT_READINESS.*
