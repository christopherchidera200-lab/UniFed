# UniFed Nigeria — Software Architecture Document (SAD)

**Version:** 1.0 (M1 baseline + target architecture)
**Owner:** UniFed Engineering (CTO)
**Status:** M1 implemented; remainder is target design

---

## 1. Introduction

UniFed Nigeria is a cloud-native **Digital University Operating System (University OS)** that unifies
communication, learning, research, campus life, creator tools, trusted academic services, and institutional
management. The first deployment is **Admiralty University of Nigeria (ADUN)**. Every future university runs
its own independent instance and connects via **ActivityPub federation**, owning its users and data.

This SAD describes both the **as-built M1 foundation** and the **target architecture** for the full spec.

### 1.1 Goals
- Serve millions of users across Nigeria and Africa.
- Federation-by-default: each university owns its instance and data.
- Production-ready, secure (NDPA 2023), scalable, observable, cloud-native.

### 1.2 Scope
- **In scope (built):** Academic Records + Digital Student ID vertical slice (backend + minimal frontend + IaC + CI).
- **In scope (target):** all 13+ feature domains in the requirements, federation, AI, blockchain trust, security.
- **Out of scope (future):** digital payments, live shopping, indoor navigation, fundraising, monetization.

---

## 2. Architectural Drivers (Quality Attributes)

| Attribute | Target | Driver |
|---|---|---|
| Scalability | Millions of users, thousands of universities | Sharded per-instance; federation boundary |
| Federation | Independent instances, owned data | ActivityPub; no central DB |
| Security / Privacy | NDPA 2023, encryption, audit | RBAC, Zero Trust, audit logging |
| Availability | 99.9% per instance | K8s, multi-AZ, stateless app tier |
| Extensibility | 13 domains, evolving | DDD bounded contexts, plugin boundaries |
| Observability | Full-stack tracing/metrics | OTel + Prometheus + Grafana |
| Cloud-agnostic | Primary AWS, portable | Terraform, containerised workloads |

---

## 3. Architecture Overview

### 3.1 As-built (M1): Rails DDD Modular Monolith
- **Stack:** Ruby on Rails 8 (modular monolith), PostgreSQL, Redis.
- **Bounded contexts (engines):** `Academic`, `Records`, `StudentId`.
- **Naming:** `Academic::Course`, `Records::GradeRecord`, `StudentId::DigitalStudentId`.
- **API:** JSON controllers under `/api/v1`.
- **Why monolith first:** fastest path to a verifiable vertical slice; clear module boundaries enable later extraction.

### 3.2 Target: Modular Monolith → Microservices
The monolith is the seed. Domains that need independent scaling (Messaging, UniFed Live, Search) are
extracted to services behind an API gateway. Federation and async events use an event bus (Redis Streams →
Kafka-compatible later).

```
                         ┌─────────────────────────────────────┐
                         │            API Gateway / Ingress    │
                         └───────────────┬─────────────────────┘
        ┌────────────────────────────────┼────────────────────────────────┐
        │                ┌───────────────┴───────────────┐                │
        │         ┌──────┴──────┐                  ┌──────┴──────┐          │
        │         │ Rails Monolith│                  │ Domain Services│          │
        │         │ (Academic,    │                  │ (Messaging,   │          │
        │         │  Records,     │                  │  Live, Search,│          │
        │         │  StudentId,   │                  │  Career, ...) │          │
        │         │  Identity,    │                  └──────┬──────┘          │
        │         │  Admin)       │                         │                  │
        │         └──────┬───────┘                         │                  │
        │                │                                  │                  │
        │         ┌──────┴───────┐                  ┌───────┴───────┐         │
        │         │ PostgreSQL    │                  │ Event Bus     │         │
        │         │ (per instance)│                  │ (Redis Streams│         │
        │         └───────────────┘                  │  → Kafka)     │         │
        │                                                └───────┬───────┘         │
        └────────────────────────────────────────────────────────┼────────────┘
                                         ┌────────────────────────┴───────────────┐
                                         │ ActivityPub Federation (instance↔instance)│
                                         │ + Consortium Blockchain (trust services)   │
                                         └───────────────────────────────────────────┘
```

### 3.3 Bounded Contexts (target)
Academic · Records · Identity (Student ID) · Federation · Social/Feed · Messaging · Collaboration ·
Media/Live · Search · Career · Marketplace · Research · Creator · Wellbeing · Alumni · Admin ·
BlockchainTrust · AI.

---

## 4. Technology Stack

| Layer | Choice |
|---|---|
| Language | Ruby (monolith), Go (high-perf services: Messaging/Live/Search), TypeScript (frontend) |
| Framework | Rails 8 (modular monolith), Next.js 14 (web), Flutter (mobile) |
| Data | PostgreSQL 16, Redis 7, S3 (media), OpenSearch (search) |
| Federation | ActivityPub (standard), Mastodon-compatible vocabulary |
| Realtime | ActionCable → WebRTC/SFU for calls, Redis pub/sub |
| IaC | Terraform (AWS), Kubernetes (EKS), Docker |
| CI/CD | GitHub Actions, GitOps (ArgoCD/Flux) |
| Observability | OpenTelemetry, Prometheus, Grafana |
| Security | OAuth2/OIDC, MFA, RBAC, Zero Trust, KMS encryption |

---

## 5. Deployment & Infrastructure (AWS, cloud-agnostic)

- **Network:** VPC (multi-AZ), NAT, private/public subnets, security groups (defined in Terraform).
- **Compute:** EKS (node groups), optionally Fargate for async workers.
- **Data:** RDS PostgreSQL 16 (Multi-AZ, encrypted, KMS), ElastiCache Redis, S3 (KMS-SSE).
- **Media:** S3 + CloudFront; streaming via MediaLive/MediaPackage or a managed SFU.
- **Secrets:** AWS Secrets Manager; IRSA for pod identity.
- **GitOps:** ArgoCD syncs `main` → cluster; Terraform state in S3 + DynamoDB lock.

---

## 6. Cross-Cutting Concerns

### 6.1 Security & Compliance (NDPA 2023)
- Data residency: PG + S3 in `af-south-1` (Cape Town, closest to Nigeria).
- Encryption at rest (KMS) and in transit (TLS).
- Audit logging for all credential/identity operations.
- RBAC per context; Zero Trust at the gateway.

### 6.2 Federation
- Each instance is an ActivityPub actor (University, not user, is the instance root).
- Users/objects addressed by `actor@instance`. No cross-instance DB.
- Trust services (credentials/diplomas) anchored on consortium blockchain; social content never on-chain.

### 6.3 Observability
- OTel instrumentation in every service; traces → Tempo/Jaeger, metrics → Prometheus → Grafana.
- SLOs per domain; alerting via Alertmanager.

### 6.4 Evolution
- Monolith → services extraction guided by the bounded-context map.
- Strangler-fig: route new domains to new services behind the gateway.

---

## 7. Risks & Decisions

| Decision | Rationale |
|---|---|
| Monolith first | Fast verifiable slice; clean boundaries enable extraction |
| Federation at instance level | Data ownership per university; ActivityPub standard |
| Blockchain for trust only | Avoid throughput/UX cost of on-chain social data |
| Go for realtime services | Ruby is poor for WebRTC/streaming hot paths |
| AWS primary, TF portable | Meets cloud-agnostic requirement while shipping |

See `docs/design/SDD.md` for component-level design and `docs/roadmap/12-18-month-roadmap.md` for delivery.
