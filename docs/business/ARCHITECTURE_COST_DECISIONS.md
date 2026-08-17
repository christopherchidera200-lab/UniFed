# UniFed Nigeria — Architecture Cost Decisions (DRAFT)

> **DRAFT — AI system-architect evaluation. KEEP/DELAY/REMOVE/REPLACE per technology. Goal: a
> financially sustainable path prototype → pilot → national, WITHOUT weakening needed capability.
> Evidence from repo: Terraform, Gemfile, FEATURE-GAP-AUDIT, ADRs, roadmap.**

---

## Decision framework
- **KEEP** now: core differentiator / already built / cheap relative to value.
- **DELAY**: valuable but premature / cost > current need.
- **REMOVE**: not recommended to remove real capability; only "remove from immediate scope."
- **REPLACE**: swap a heavy default for a lighter one at current stage.

## Per-technology verdict

| Technology | Verdict | When justified | Note |
|---|---|---|---|
| PostgreSQL (RDS) | **KEEP** | Always | Core; Multi-AZ only at scale |
| Redis (ElastiCache) | **KEEP** (1 node pilot) | Always | Required (rate-limit/obs) |
| Kubernetes (EKS) | **DELAY→KEEP** | Pilot: NO (use EC2/App Runner/Coolify); Scale: YES | EKS control plane $73/mo + nodes; premature at 1 node |
| Terraform | **KEEP** | Always | Portable IaC; already defined |
| Object storage (S3) | **DELAY** | When media/files needed | Not required now (no storage.yml) |
| OpenSearch | **DELAY** | When PG ILIKE insufficient / semantic search | Current search = PG ILIKE |
| API Gateway | **DELAY** | Scale / per-uni metering | Pilot: ingress/ALB enough |
| ActivityPub federation | **KEEP** (harden) | Always (differentiator) | Close F-04/05/06 before broad fed |
| Consortium blockchain | **REMOVE from scope (delay)** | Only as credential anchor, later | Not built; high cost/complexity |
| GIS/PostGIS | **DELAY** | Smart Campus phase | Optional ext; degrade gracefully |
| AI services | **DELAY** | Phase 6; guard tokens | Cost explosion risk → cost controls mandatory |
| Live streaming | **DELAY** | Phase 3; Go worker | Heavy egress/compute |
| Observability (OTel/Prom/Grafana/Loki) | **KEEP (lite)** | Always; Loki optional | CloudWatch suffices early |
| CDN (CloudFront) | **KEEP at scale** | When media/egress grow | Cuts egress cost |
| Event-driven (Sidekiq/Go workers) | **KEEP lite** | Async jobs; extract to Go at scale | Default :async now; fine |
| WAF/Shield | **DELAY→KEEP** | Public scale / DDoS | Pilot: basic SG + headers enough |

## MVP / Pilot / Scale architectures

### MVP (now, $0)
Local Compose (postgres+redis+rails+next). No cloud.

### Pilot (Stage 1, ~$0–$1.5k/mo)
Single EC2/Coolify OR App Runner; single-AZ RDS; 1 Redis node; Route53+ACM; CloudWatch.
**No EKS, no OpenSearch, no S3, no API GW.** Right-size Terraform DOWN.

### Scale (Stage 3+, ~$150k–$400k/yr)
EKS + Aurora Serverless + OpenSearch + CloudFront + WAF + per-uni namespaces; Go federation workers;
AI with cost guards; DR.

## Cost guardrails (mandatory)
- No EKS before ≥3 unis.
- No OpenSearch before PG search insufficient.
- AI behind token caps + caching + routing (avoid 10× infra cost).
- Egress budgeted explicitly (federation multiplier).
- Multi-AZ/RDS replicas only where SLA demands.

## What NOT to remove
Federation, signed credentials, NDPA consent, RBAC, auth — these are the product/trust, not cost
to cut. Defer *infrastructure heaviness*, not *capability*.

*See CLOUD_COST_ANALYSIS.md (stages), FINANCIAL_RISK_REGISTER.md (mitigations).*
