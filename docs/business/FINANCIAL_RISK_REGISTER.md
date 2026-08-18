# UniFed Nigeria — Financial Risk Register

> Risks rated by likelihood × impact. Mitigations are operational, not speculative. Cost figures
> trace to `CLOUD_COST_ANALYSIS.md` / `FINANCIAL_MODEL.md`.

| # | Risk | L | I | Score | Mitigation |
|---|---|---|---|---:|---|
| R1 | **Cloud cost explosion** (egress/media at scale) | M | H | 12 | CDN (CloudFront), signed URLs, per-uni media budgets, right-sized stages |
| R2 | **AI API cost explosion** (premium features) | M | M | 9 | Cap per-user spend, cache inferences, self-host small models later |
| R3 | **Bandwidth costs** (federation/video) | M | H | 12 | CDN + regional edge + offline-tolerant design |
| R4 | **Video/live-stream costs** (UniFed Live) | L | H | 8 | Defer to Stage 3; use managed SFU; transcode-on-demand |
| R5 | **Storage costs** (media/docs) | L | M | 6 | Lifecycle policies, tiering, dedupe |
| R6 | **Cybersecurity costs** (pentest, monitoring) | M | M | 9 | Continuous (STRIX cadence), IaC hardening, MFA/OIDC |
| R7 | **Staffing costs** (80% of opex) | H | H | 15 | Fractional roles, grants for stipends, lean run-rate |
| R8 | **Slow university procurement** | H | H | 15 | Free pilot → paid, grants for public uni, LOIs early |
| R9 | **Long sales cycles** | H | H | 15 | Federation referrals lower CAC, reference-driven GTM |
| R10 | **Regulatory costs** (NDPA, data residency) | M | H | 12 | NDPA-by-design, DPO, af-south-1 residency |
| R11 | **Federation complexity** (F-04/05/06) | M | H | 12 | Go worker + signature/replay hardening before scale |
| R12 | **Low adoption / churn** | M | H | 12 | Free end-users, portable identity, pilot retention metric |
| R13 | **Student churn** | M | M | 9 | Consumer-grade UX, mobile-first, network value |
| R14 | **Dependence on grants** | M | H | 12 | Diversify (institutional license) before scale |
| R15 | **Dependence on one university (ADUN)** | M | H | 12 | Multi-node pipeline; federation lowers single-node risk |
| R16 | **Infra vendor lock-in (AWS)** | L | M | 6 | Terraform portable, cloud-agnostic design, OSS |

**Top 3 financial risks:** R7 (staffing), R8/R9 (procurement/sales cycles), R1/R3 (cloud/egress).
**Mitigation theme:** pilot-first to de-risk revenue; right-size infra; diversify funding; federation
to lower CAC and single-university dependence.
