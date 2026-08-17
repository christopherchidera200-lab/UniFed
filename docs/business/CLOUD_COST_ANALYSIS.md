# UniFed Nigeria — Cloud Cost Analysis (DRAFT)

> **DRAFT — cloud economics. Indicative 2026 AWS pricing ranges; VERIFY against live AWS Pricing
> Calculator before commitment. No infrastructure will be deployed (per instructions). Assumptions
> labelled [A1]… and explained. Staging today is $0 (local/documented Coolify).**

---

## 0. Method & assumptions

- Currency USD. Rates are **order-of-magnitude ranges**, not quotes.
- [A1] Exchange/inflation ignored; Nigerian billing may be in USD or local.
- [A2] Prices reflect on-demand; savings plans/reserved cut 30–60% at steady state.
- [A3] "Per node" = one university's independent instance (its own DB/cache/compute).
- [A4] Data egress priced ~$0.05–0.09/GB out; federation adds cross-node traffic.
- [A5] No object storage / OpenSearch initially (staging report: not required yet).
- [A6] Managed services (RDS/ElastiCache/EKS) chosen for pilot readiness; self-managed cheaper
  but needs ops headcount.

## 1. Staged infrastructure models

### STAGE 0 — $0 local dev
- Local Postgres + Redis + Rails + Next (developer machines / CI).
- **Cost: $0 cloud.** Limit: not production.

### STAGE 1 — ADUN pilot (1 node, modest)
**Minimum viable (cost-sensitive):** single small EKS or EC2 + RDS db.t3.medium + ElastiCache
cache.t3.micro + Route53 + ACM + basic CloudWatch. Optional Coolify on a small VPS (~$0 if using
free/early tier).
- **Monthly: ~$750–$1,500** → **Annual: ~$9k–$18k.**
- Drivers: RDS (largest), EKS control plane ($73/mo) or skip EKS for pilot (use EC2/App Runner).
- **Cost-saving alt:** Coolify/EC2 single host ~$30–$80/mo; or AWS Free Tier for first 12 months
  (near $0). Recommended for pilot validation.

### STAGE 2 — 1–3 universities
Per node ~$750–$1,500/mo + shared control plane + monitoring + CI runners.
- **Annual: ~$30k–$70k** (3 nodes + shared services).
- Alt: shared EKS + per-uni namespaces; federation traffic low.

### STAGE 3 — 10–20 universities
Per-uni RDS + cache + ingress; shared EKS, Prometheus/Grafana, OpenSearch for search, S3 media.
- **Annual: ~$150k–$400k.** Drivers: 20× RDS + egress + OpenSearch + AI (if on).
- Alt: read replicas, Aurora Serverless v2 (scale-to-zero), spot for batch.

### STAGE 4 — 50+ universities
Multi-AZ, Aurora Serverless, ElastiCache clusters, WAF/Shield, data egress at scale, DR.
- **Annual: ~$700k–$1.5M.** Drivers: egress (federation), storage, support ops.

### STAGE 5 — National/Africa
Regional hubs, multi-region, heavy AI, streaming, DR, 24/7 SRE.
- **Annual: $2M–$5M+.** Requires financing/grants.

## 2. Per-service build-up (Stage 1 reference, monthly)

| Service | Option | ~Cost/mo |
|---|---|---|
| Compute (Rails+Next) | EKS 2×t3.medium OR EC2 t3.large | $60–$140 |
| RDS PostgreSQL | db.t3.medium Multi-AZ | $130–$210 |
| ElastiCache | cache.t3.micro | $12–$25 |
| EKS control plane | — | $73 |
| S3 (media, light) | — | $5–$20 |
| Route53 + ACM | — | ~$1–$6 |
| CloudWatch/Logs | — | $10–$40 |
| NAT GW + egress | — | $45–$90 |
| Backup/DR (snapshots) | — | $10–$30 |
| **Total** | | **~$350–$630** (lean, no EKS) / **~$750–$1,500** (EKS) |

> Note: Terraform defines Multi-AZ RDS + 2-node ElastiCache + EKS (heavier). For pilot, right-size
> DOWN (single-AZ RDS, skip EKS, one cache node) until validated.

## 3. Major cost drivers (ranked)
1. Personnel (engineering/DevOps/SRE) — dwarfs infra at every stage.
2. RDS (Multi-AZ, storage, backups).
3. EKS control plane + node groups.
4. Data egress (federation multiplies this).
5. AI/LLM API consumption (only when AI ships).
6. NAT Gateway (per-AZ).
7. OpenSearch (only when semantic search on).

## 4. Cost-saving alternatives (do NOT weaken capability)
- Pilot: Coolify/single EC2 or App Runner instead of EKS.
- DB: Aurora Serverless v2 (scale-to-zero) instead of fixed Multi-AZ for low-traffic unis.
- Cache: one node, not two, at pilot.
- Egress: keep federation payloads lean; compress; cache at edge (CloudFront).
- Compute: reserved/savings plans once steady; spot for batch/CI.
- OpenSearch: defer until PG `ILIKE`/full-text insufficient (current state).

## 5. Scaling risks
- **Egress blow-up** as federation grows (each node pushes to many) → budget egress explicitly.
- **Per-uni fixed cost** makes small/unis uneconomic unless pooled (shared services, thin nodes).
- **AI token costs** can exceed infra 10× if unmetered → require cost guards (caching, routing, caps).
- **Multi-AZ everywhere** by default = 2–3× cost; right-size per tier.

## 6. Recommended architecture by stage (see ARCHITECTURE_COST_DECISIONS.md)
- MVP/Pilot: single host or App Runner; no EKS; single-AZ RDS; no OpenSearch.
- Scale: EKS + Aurora Serverless + OpenSearch + CloudFront + WAF; per-uni namespace isolation.

*Full unit economics in UNIT_ECONOMICS.md; projections in 3_YEAR_FINANCIAL_PROJECTIONS.md.*
