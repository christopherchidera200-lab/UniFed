# UniFed Nigeria — Architecture Cost Decisions (KEEP / DELAY / REMOVE / REPLACE)

> AI System Architect view. Goal: a **financially sustainable path** prototype → pilot → national,
> without weakening the architecture. "REMOVE" is used only for genuinely premature/duplicated items;
> important capabilities are **DELAYED**, not removed.

| Technology | Decision | Rationale / when justified |
|---|---|---|
| Kubernetes (EKS) | **KEEP (parameterize)** | Needed at Stage 2+; for pilot, right-size to 1–2 nodes or use ECS Fargate. As-coded 3× m6i.large is pilot-overkill. |
| Terraform | **KEEP** | Portable IaC; foundation already validated. |
| Modular monolith | **KEEP** | Correct for M1; extract domains (Messaging/Live/Search) to services at Stage 2. |
| PostgreSQL (+PostGIS) | **KEEP** | Core; PostGIS only when Smart Campus maps ship (Stage 3). |
| Redis / ElastiCache | **KEEP** | Sessions/cache; 1 node at pilot, 2 at prod (as-coded). |
| Object storage (S3) | **KEEP** | Media; essential. CDN in front at Stage 2. |
| API Gateway | **DELAY** | Not configured yet; add at Stage 2 when services extracted. |
| ActivityPub federation | **KEEP (build now)** | Core differentiation; Go worker + F-04/05/06 closure before scale. **Do not remove.** |
| Consortium blockchain | **DELAY** | Trust-anchoring only; defer until credentials volume justifies. Avoid on-chain social. |
| GIS / PostGIS | **DELAY** | Only with Smart Campus maps (Stage 3). |
| AI services | **DELAY** | Premium feature; Stage 2+; cap API spend. |
| Live streaming (WebRTC/LiveKit) | **DELAY** | Stage 3; managed SFU; transcode-on-demand. |
| Observability (Prom/Graph/Loki/OTel) | **KEEP (light)** | Deploy minimal at pilot; scale at Stage 2. Currently not deployed — gap. |
| OpenSearch / search | **DELAY** | Build when Discover/Search ships (Stage 2). |
| CDN (CloudFront) | **KEEP (add at Stage 2)** | Cuts egress; essential before media scale. |
| Event-driven (Redis Streams→Kafka) | **DELAY** | Introduce when async domains extracted (Stage 2+). |
| Microservices | **DELAY (extract, don't rewrite)** | Strangler-fig from monolith per bounded context. |

## Architecture stages (cost-justified)
- **MVP (now):** monolith + PG + Redis + S3 + minimal observability. $0 local, ~$400/mo pilot.
- **Pilot (ADUN):** + right-sized EKS (or Fargate) + KMS + Secrets Manager + light Prometheus.
- **Scale (10–50 uni):** + API gateway, OpenSearch, CDN, event bus, extracted services, MFA/OIDC.

## Principle
Do **not** remove capabilities to cut cost. Instead **sequence** them: build the federated core now
(the moat), defer media/AI/GIS/blockchain until usage justifies the spend. This keeps UniFed
ambitious yet financially disciplined.
