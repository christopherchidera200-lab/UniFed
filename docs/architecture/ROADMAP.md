# UniFed Nigeria — Engineering Roadmap

## M1 — Foundation + Vertical Slice 1 (IN PROGRESS)
**Goal:** production-grade foundation + one end-to-end vertical slice.
- [x] Repo strategy (ADR-0001) — `UniFed.git` canonical, CloudIntel archived
- [x] Modular monolith skeleton (ADR-0002)
- [x] ADUN academic data model (ADR-0005) + PostgreSQL DDL
- [x] Auth architecture (ADR-0004) — OIDC/MFA/MFA
- [x] Federation architecture (ADR-0003) — ActivityPub
- [x] Terraform AWS foundation (VPC, EKS, RDS, ElastiCache, OpenSearch, S3)
- [x] K8s + Docker manifests, GitHub Actions CI (backend/frontend/terraform)
- [x] Rails: Academic + Records + StudentId contexts (models, services, controllers)
- [x] RSpec specs for slice-1 domain logic
- [x] Next.js design system + 5-tab nav + Academic Records screen
- [ ] **Founder approval before merge to master** (gate)

## M2 — Vertical Slice 2: Connect + Federation
- ActivityPub actor/inbox/outbox (Go federation worker)
- Home feed, Connect, Discover across nodes

## M3 — Slice 3: Events + Campus (fills ADUN empty-calendar gap)
## M4 — Slice 4: Marketplace / Career / Creator
## M5 — Consortium blockchain credential anchoring (deferred context)

## Open questions to resolve with ADUN (⚠️ from brief)
1. Official matric-number code scheme + staff-ID scheme
2. Full course catalogues per department (all programmes)
3. Grading scale + classification bands
4. Fee schedule; staff directory; SIWES timelines
5. ICT Directorate IT/SSO policy (interop w/ ASIS/SPGS)
6. Official ADUN brand assets (colours, logos) — theming slots reserved
