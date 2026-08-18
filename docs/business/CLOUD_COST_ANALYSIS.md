# UniFed Nigeria — Cloud Cost Analysis

> **Scope:** Infrastructure cost modeling only. This is a *planning* exercise over the actual
> repository (Terraform in `infra/terraform`, Docker Compose in `infra/docker`, CI in
> `.github/workflows`). No infrastructure was deployed; all figures are **estimates** using
> mid-2026 AWS list pricing for region **af-south-1 (Cape Town)** — the region the Terraform
> pins as closest to Nigeria. af-south-1 carries a ~10–15% premium over us-east-1.
> **Every price must be re-verified against the AWS pricing calculator before any commitment.**

---

## 1. What the repository actually defines (evidence, not assumption)

`infra/terraform/main.tf` + `variables.tf` define the **ADUN reference node**:

| Component | As-coded spec | Implication |
|---|---|---|
| VPC | 3 AZ, **`single_nat_gateway = false`** → 3 NAT Gateways | High egress floor |
| KMS | 1 key, rotation on | ~$1/mo |
| RDS PostgreSQL 16.4 | `db.r6g.large`, **Multi-AZ**, 100 GB gp3, 14-day backup, KMS | ~$0.34/hr ×2 |
| ElastiCache Redis 7.1 | `cache.r6g.large` × **2 nodes**, encryption in transit + at rest | ~$0.34/hr ×2 |
| S3 media | KMS-SSE, public access blocked | egress-dominated |
| EKS 1.30 | managed node group, `m6i.large`/`m6i.xlarge`, **desired 3, 2–6** | control plane + 3 nodes |
| Security groups | RDS/Redis ingress scoped to VPC CIDR | — |

The local `docker-compose.yml` runs postgres + redis + opensearch + minio + backend ($0 cost).

**Critical observation:** the as-coded pilot spec is **over-provisioned for a single-university pilot**.
3 NAT gateways, Multi-AZ RDS, a 2-node Redis cluster, and 3× m6i.large EKS nodes are a
*production-scale* baseline, not a validation pilot. This analysis separates the **as-coded**
cost from a **right-sized pilot** cost.

---

## 2. Staged infrastructure models

All monthly figures are ranges (low–high) in USD. Annual = monthly × 12.

### STAGE 0 — $0 local development
- Stack: Docker Compose on a developer laptop / single VM.
- **Monthly infra cost: $0** (compute already owned).
- Cost driver: none. This is the current state of the project.

### STAGE 1 — ADUN pilot (1 university, <5k users)
**Minimum viable (right-sized):**
- 1× EKS node `m6i.large` (or ECS/Fargate single service) — $140/mo
- RDS `db.t3.medium` single-AZ, 50 GB — $65/mo
- ElastiCache `cache.t3.micro` ×1 — $20/mo
- 1 NAT Gateway — $33/mo + egress
- S3 + CloudFront + KMS + Secrets Manager + ELB — $40/mo
- CloudWatch/Prometheus (light) — $25/mo
- **Right-sized pilot total: ~$320–$450/mo (~$3.8k–$5.4k/yr)** + egress.

**As-coded (current Terraform, not recommended for pilot):**
- 3× `m6i.large` EKS + control plane — ~$500/mo
- RDS `db.r6g.large` Multi-AZ — ~$500/mo
- Redis `cache.r6g.large` ×2 — ~$500/mo
- 3 NAT Gateways — ~$100/mo + egress
- S3/CF/KMS/ELB/Secrets — ~$80/mo
- **As-coded total: ~$1,600–$1,900/mo (~$19k–$23k/yr)** + egress.

> **Recommendation:** deploy the right-sized pilot; the as-coded Terraform should be parameterized
> by `stage` (pilot vs prod) before any real deployment. Multi-AZ, 2-node Redis, and 3 NATs are
> production hardening, not pilot requirements.

### STAGE 2 — 1–3 universities (federated)
- Each node ≈ right-sized pilot ($350–$450/mo) **or** a shared platform model.
- **Recommended:** shared control-plane + per-university data isolation (logical, not physical
  clusters) for 2–3 nodes → **~$900–$1,500/mo (~$11k–$18k/yr)**.
- Major driver: per-university RDS + Redis replication; federation worker (Go) compute.

### STAGE 3 — 10–20 universities
- Shared Kubernetes platform, per-tenant namespaces, regional RDS with read replicas.
- **~$6k–$12k/mo (~$72k–$144k/yr)**.
- Driver: database IOPS, search (OpenSearch), media storage, federation fan-out bandwidth.

### STAGE 4 — 50+ universities
- Multi-region, autoscaling node pools, dedicated search/media tiers, CDN-heavy.
- **~$30k–$60k/mo (~$360k–$720k/yr)**.
- Driver: egress (CDN mitigates), media/live-streaming, OpenSearch fleet, on-call/SRE.

### STAGE 5 — National/Africa scale (100s of nodes)
- **$150k–$400k+/mo (~$1.8M–$4.8M/yr)**.
- Driver: video/live-stream, AI inference, cross-region federation, compliance/DR.

---

## 3. Major cost drivers (ranked)
1. **Compute (EKS nodes / RDS / Redis)** — dominant at every stage.
2. **NAT Gateway egress** — 3 NATs in as-coded spec is wasteful; 1 NAT + private API egress is enough for a pilot.
3. **Data transfer / egress** — grows with media, video, federation.
4. **Managed services premium** (RDS Multi-AZ, ElastiCache) — justify by tier.
5. **Observability & logging** — Prometheus/Grafana/Loki/OTel storage accrues.
6. **AI/API consumption** — only at Stage 2+ (none built today).

---

## 4. Cost-saving alternatives (do NOT weaken capability)
- **Pilot:** single NAT, single-AZ RDS (snapshot backups), 1 Redis node, 1–2 small EKS nodes or ECS Fargate.
- **Spot/reserved instances** at Stage 2+ for node groups (RI = ~30–60% saving).
- **CloudFront** in front of S3/media to cut origin egress.
- **Consolidated platform** (one cluster, per-tenant isolation) instead of one cluster per university at Stage 2–3.
- **MinIO/S3-compatible on own infra** only if a university mandates data-residency-on-prem (avoid premature).
- **Serverless async** (Fargate/Lambda) for the Go federation worker instead of always-on nodes.

---

## 5. Scaling risks
- **Egress explosion** if media/video federation is mis-architected (CDN + signed URLs mandatory).
- **NAT multiplication** — never replicate 3-NAT pattern per node.
- **RDS IOPS caps** at scale → move hot domains to dedicated instances / read replicas.
- **OpenSearch cost** — can dominate search-heavy stages; consider managed OpenSearch Serverless.

---

## 6. Bottom line
The project's $0 local staging is **not** the production cost. A credible ADUN pilot can run at
**~$350–$450/mo** if the Terraform is right-sized; the current as-coded spec implies ~$1.7k/mo and
should be parameterized before spend. Treat cloud cost as a **funded requirement** unlocked by
pilot/grant/seed capital, not a constraint that should shrink the architecture.
