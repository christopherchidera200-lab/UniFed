# UniFed Nigeria — Digital University Operating System

> **Connect • Learn • Create • Verify • Grow**

UniFed is Africa's first cloud-native **Digital University Operating System (University OS)**:
a federated platform that unites social networking, academic collaboration, learning, AI
education, a creator economy, digital student identity, academic records, and consortium
blockchain verification into one coherent product.

This repository is the **reference implementation**, whose first production deployment is
**Admiralty University of Nigeria (ADUN)** — `adun.unifed.ng`. Every additional university
deploys its own independent instance and joins the federation over **ActivityPub**.

```
adun.unifed.ng  (reference node)
   ├─ unilag.unifed.ng
   ├─ unn.unifed.ng
   ├─ ui.unifed.ng
   ├─ uniport.unifed.ng
   └─ …future universities
```

Each university **owns its users, content, moderation, policies, and infrastructure**.
ADUN is the first federation node — not the central owner of all data.

---

## Technology Direction

| Layer | Choice |
|-------|--------|
| Frontend | React, Next.js (App Router), TypeScript, Tailwind |
| Mobile | Flutter (planned) |
| Backend | **Ruby on Rails** (primary, ActivityPub-native) + **Go** for high-performance components |
| Database | PostgreSQL (+ PostGIS), Redis, OpenSearch, S3/MinIO |
| Federation | ActivityPub (JSON-LD) |
| Streaming | WebRTC, LiveKit / MediaMTX, FFmpeg (later phases) |
| GIS | PostGIS, GeoServer (later phases) |
| Auth | OAuth2, OpenID Connect, MFA |
| Infra | Kubernetes, Docker, Terraform, Helm, GitHub Actions, GitOps |
| Observability | Prometheus, Grafana, Loki, OpenTelemetry |
| Cloud | AWS (primary), portable to Azure / GCP / OpenStack / on-prem |

## Architecture Principles

Domain-Driven Design · Clean / Hexagonal Architecture · Event-Driven · API-First ·
Infrastructure as Code · Twelve-Factor · Secure-by-Design · Privacy-by-Design ·
Cloud-Native · Loosely-Coupled Modules.

See [`docs/architecture`](docs/architecture) for the full set of ADRs and bounded-context maps.

## Repository Layout

```
unifed/
├─ backend/            # Ruby on Rails API (modular monolith, DDD bounded contexts)
├─ frontend/          # Next.js web client (design system + modules)
├─ mobile/            # Flutter app (later phase)
├─ infra/
│  ├─ terraform/      # AWS foundation (VPC, EKS, RDS, ElastiCache, OpenSearch, S3)
│  ├─ k8s/            # Kubernetes manifests / Helm
│  └─ docker/         # Dockerfiles, compose
├─ docs/
│  ├─ architecture/   # ADRs, system context, bounded contexts
│  └─ api/            # API specifications
└─ scripts/           # tooling
```

## Current Milestone

**M1 — Foundation + Vertical Slice 1: Academic Records & Digital Student ID.**
Build the production-grade foundation (monorepo, DDD skeleton, ADUN academic data model,
OAuth2/OIDC + MFA auth, ActivityPub federation core) and ship one end-to-end vertical slice
with tests, docs, IaC, and observability hooks.

## Getting Started (local)

```bash
# Backend
cd backend && bundle install && rails db:setup && rails test

# Frontend
cd frontend && npm install && npm run dev
```

> Local development uses PostgreSQL. See `infra/docker/docker-compose.yml` for the full stack.

## License

Proprietary — UniFed Nigeria. Internal engineering use.

