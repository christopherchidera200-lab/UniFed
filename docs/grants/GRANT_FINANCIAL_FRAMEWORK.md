# UniFed Nigeria — Grant Financial Framework

> Recommended budget structure for grant applications. Figures are **planning estimates** (USD) to be
> re-derived per call. Aligned with `FINANCIAL_MODEL.md`. No grant is asserted as awarded.

## 1. Project budget categories (indicative, pre-seed grant ~$250k equivalent)

| Category | % | Est. (low–high) | What it pays for |
|---|---:|---:|---|
| Development (engineering) | 40% | $100k–$160k | Finish M1 slice, ADUN pilot, federation core, 2–3 domains |
| Infrastructure | 8% | $15k–$30k | Right-sized pilot cloud (EKS/RDS/Redis/S3/KMS), CI |
| Security | 12% | $25k–$45k | Close STRIX F-04/05/06/07/11/12, MFA/OIDC, monitoring |
| AI (foundation) | 5% | $10k–$20k | AI tutoring/analytics R&D plan + ethics framework |
| GIS (planning) | 3% | $5k–$12k | Smart Campus maps design (PostGIS) — Stage 3 |
| Research collaboration | 5% | $10k–$20k | Research hub build + cross-uni pilot |
| University deployment | 10% | $20k–$35k | ADUN deploy, ICT/SSO integration, training, onboarding |
| Training / capacity | 4% | $8k–$15k | University staff + student training, docs |
| Operations | 6% | $12k–$20k | SRE, support, project management |
| Legal / compliance | 5% | $10k–$20k | LICENSE file, IP assignment, NDPA/DPIA, entity |
| Monitoring / evaluation | 2% | $4k–$8k | KPIs, baseline, impact reporting (per `impact/` framework) |

## 2. Utilization framework (principles)
- **Milestone-gated:** releases tied to ADUN pilot live → federation demo → 2nd university.
- **Non-dilutive-first:** grants fund build; revenue funds scale.
- **Transparent:** category caps; quarterly reporting; audit-ready.
- **Sovereign-data compliant:** infra in af-south-1; NDPA-aligned handling.
- **OSS obligation:** deliverables under chosen LICENSE; maintenance budgeted.

## 3. What grants should NOT fund
- Pure commercial sales/marketing at scale (use revenue).
- Perpetual run-rate beyond pilot (transition to institutional license).
- Speculative blockchain/mainnet (trust-anchoring only, deferred).

## 4. Evidence to attach (build pack)
Registered entity · LICENSE · IP assignment · ADUN MOU · STRIX reports · architecture/ADRs ·
impact framework · budget · pilot plan · DPIA/consent drafts · team CVs.

## 5. Stage mapping
- **Pre-seed grant (~$250k):** development + security + deployment + legal (above).
- **Stage 2 grant (~$1M):** federation + domains + AI/GIS + multi-uni.
- **Scale grant:** national rollout + research + DPI.

See `GRANT_READINESS.md` for category fit + gaps; `FINANCIAL_MODEL.md` for run-rate context.
