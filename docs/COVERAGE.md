# UniFed Nigeria — Feature Coverage Matrix

> Status of the full "Complete Feature Requirements" spec against the codebase as of M1.
> Legend: ✅ Built & verified · 🟡 Partial/scaffolded · 📋 Target (designed, not built) · ❌ Absent

This is an honest gap report. Only the Academic Records + Digital Student ID domains are implemented.
Everything else is planned and described in the SAD / SDD / Roadmap.

## Navigation (5 tabs)

| Tab | Status | Notes |
|---|---|---|
| Home | ❌ | Feed/announcements/stories — not built |
| Connect | ❌ | Messaging/calls/collab — not built |
| Create (+) | ❌ | Posts/stories/livestreams — not built |
| Discover | ❌ | Search — not built |
| Profile | 🟡 | Digital Student ID + Academic Records backend exist; UI thin |

## Feature domains

| Domain | Status | What exists |
|---|---|---|
| Academic Records | ✅ | Course, CourseOffering, GradeRecord, AcademicSummary, NUC bands, CGPA, AcademicSummaryService, API |
| Digital Student ID | ✅ | DigitalStudentId, IdIssuanceService (signed JWT QR), IdVerificationService, verification_logs, API |
| Federation (ActivityPub) | ❌ | No federation code; design only |
| Connect — Messaging | ❌ | No chat/calls |
| Connect — Collaboration | ❌ | No whiteboard/docs/calendar |
| Connect — AI Features | ❌ | No AI services |
| Connect — Campus Maps | ❌ | No maps |
| Connect — UniFed Live | ❌ | No streaming |
| Connect — Emergency | ❌ | No SOS |
| Create | ❌ | No content creation |
| Discover / Search | ❌ | No search |
| Smart Campus | ❌ | No maps/navigation |
| UniFed Live | ❌ | No streaming |
| Career Hub | ❌ | No careers |
| Marketplace | ❌ | No marketplace |
| Research Hub | ❌ | No research |
| Creator Economy | ❌ | No creator tools |
| Digital Wallet | ❌ | Future |
| Student Wellbeing | ❌ | No wellbeing |
| Alumni | ❌ | No alumni |
| Administration Portal | 🟡 | Models exist (University/Faculty/Dept/Programme) but no admin UI/roles |
| AI | ❌ | No AI platform |
| Consortium Blockchain | ❌ | No blockchain; design only |
| Security | 🟡 | RBAC-ish via contexts; no MFA/OAuth/OIDC/Zero Trust |

## Infrastructure

| Capability | Status | Notes |
|---|---|---|
| Kubernetes (EKS) | 🟡 | Terraform defines EKS; no workloads deployed |
| Docker | 🟡 | Dockerfile.rails exists; not built/pushed |
| Terraform | ✅ | VPC, RDS, ElastiCache, S3, EKS, KMS validate & fmt-clean |
| CI/CD (GitHub Actions) | ✅ | backend-ci, frontend-ci, terraform-plan all green |
| PostgreSQL / Redis | ✅ | Provisioned in Terraform |
| Object Storage (S3) | ✅ | Bucket defined |
| API Gateway | ❌ | Not configured |
| Prometheus / Grafana / OTel | ❌ | Not deployed |

## Honest summary

- **Implemented & green:** 2 backend domains (Academic Records, Digital Student ID), Terraform foundation, 3 CI pipelines.
- **Designed but not built:** the remaining ~13 domains, federation, AI, blockchain, security hardening, full UI/UX.
- **Effort to full spec:** this is a multi-team, 12–18 month programme (see `docs/roadmap/12-18-month-roadmap.md`), not a single-developer task.

The documents in this folder describe the **target** architecture and the phased plan to deliver the full spec.
