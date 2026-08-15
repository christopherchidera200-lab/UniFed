# UniFed Nigeria — Feature Gap Audit

> Authoritative basis: live inspection of `backend/app/contexts/*`, `backend/app/controllers/api/v1/*`,
> `backend/config/routes.rb`, `frontend/src/pages/*`, `db/migrate/*` at commit `d9d2572`.
> Classification legend: ✅ implemented & functional · 🟡 partial · 🔴 missing · 🟣 planned/future · ⚠️ functional but needs hardening.

## 0. Methodology note (no fabricated features)
A UI page existing does **not** count as implemented. Every claim below was verified against
backend context code, controllers, services, and specs. Keyword probes for `gis`, `messag`,
`admin`, `campus` returned hits, but these were **false positives** (matched `university`,
federation delivery, RBAC role checks) — there are no such domains yet.

## 1. Audit summary table

| # | Feature area | Status | Evidence |
|---|---|---|---|
| 1 | Identity / Auth (OIDC, MFA, RBAC) | ✅ | `identity` ctx: 8 models, 8 svc, 3 specs; `auth`,`mfa`,`roles` controllers |
| 2 | Federation (ActivityPub) | ⚠️ + 🟡 | `federation` ctx 3 models, 6 svc; inbox/outbox/webfinger present; **F-04/05/06 open** |
| 3 | Academic Records + Student ID | ✅ | `academic`(12 models),`records`(3),`student_id`(2); strict authz verified |
| 4 | Social Feed | ✅ | `social` ctx; `feed` controller create/react/comment |
| 5 | Library | ✅ (BOLA fixed F-10) | `library` ctx; borrow/return/resources |
| 6 | Career Hub | 🟡 | `career` ctx present but minimal (opps/apply/save only) |
| 7 | SIWES | ✅ | `siwes` ctx; placement/logs/verify |
| 8 | Catalog / Search | 🟡 | `catalog` + `search` present; **no semantic search**, no unified discovery |
| 9 | Calendar / Events | 🟡 | `calendar` events + `examinations`; no scheduling UI/data model |
| 10 | Assessment / Grading | 🟡 | `assessment` ctx = basic score rollup → `grade_records`; **no assignment LMS** |
| 11 | **GIS / Smart Campus** | 🔴 | no `campus`/`building`/geo model or service |
| 12 | **Assignments / LMS** | 🔴 | no submissions, deadlines, rubrics, lecturer grading workflow |
| 13 | **Administration portal** | 🔴 | RBAC exists; no admin controllers/UI for managing univ entities |
| 14 | **Research Hub** | 🔴 | no `research`/`publication` domain |
| 15 | **Connect / Messaging** | 🔴 | no conversation/message model, no realtime |
| 16 | **Marketplace** | 🔴 | no listing/seller model |
| 17 | **Alumni** | 🔴 | no alumni model/relationship |
| 18 | **Wellbeing** | 🔴 | no counselling/medical foundation |
| 19 | **Creator Economy** | 🔴 | no creator profile/analytics domain |
| 20 | **AI Platform abstraction** | 🔴 | no `Ai::*` service/provider interface |
| 21 | **UniFed Live / Streaming** | 🔴 | no `LiveStreamingService` abstraction |
| 22 | **Blockchain verification** | 🔴 | no `CredentialVerificationService` interface |
| 23 | **Digital Wallet** | 🟣 | future; out of scope this milestone |
| 24 | **Cloud infra (AWS/k8s/Terraform)** | 🟣 | explicitly reserved for grant/cloud stage |

## 2. Detailed findings

### 2.1 ✅ Implemented & functional
- **Identity & Auth**: OIDC token issuer, login/register/logout/refresh, TOTP MFA, RBAC roles+permissions, NDPA consent, audit logging. Controllers: `auth`,`mfa`,`roles`,`consent`,`oidc`.
- **Academic Records**: student lookup (`/academic/me`), records/summary, signed transcript issue+verify, digital student ID issue+verify. Authorization: university-scoped, role-checked.
- **Social**: feed timeline, create post, react, comment.
- **Library**: browse, borrow, return (ownership-scoped after F-10 fix).
- **SIWES**: placement, logs, completion, log verification.
- **Federation (core)**: WebFinger, actor inbox, outbox, JWKS, OIDC discovery.

### 2.2 ⚠️ Functional but needs hardening
- **Federation (F-04/F-05/F-06)**: remote key fetch is a stub (SSRF latent), Follow auto-accepted, Delete no-op, no inbox replay protection, no HTTP signature verification. Core differentiator — must be secured before broad federation.

### 2.3 🟡 Partial
- **Assessment/Grading**: `AssessmentService.record!` + `rollup!` produce `grade_records`. This is a grade *rollup*, **not** an LMS (no assignment definition, submission, deadline, rubric, lecturer grading UI, student submission history).
- **Career**: opportunities/recommendations/applications/apply/save exist; missing internship portal, employer verification, alumni mentoring, CV builder, AI review.
- **Catalog/Search**: course catalog + basic search present; no semantic search, no unified discovery across entities.
- **Calendar/Events**: events listing exists; no timetable, scheduling, or location linking.

### 2.4 🔴 Missing (the real gaps)
| Area | What's absent |
|---|---|
| GIS / Smart Campus | no `campus`, `building`, geo model; no lat/long; no map abstraction |
| Assignments / LMS | no `Assignment`, `Submission`, `Rubric` models; no workflow |
| Administration | no admin controllers/UI; RBAC primitives exist but unused for ops |
| Research Hub | no research profiles/groups/publications/projects domain |
| Connect / Messaging | no `Conversation`/`Message`/reactions/receipts model |
| Marketplace | no `Listing`/`Seller` model |
| Alumni | no alumni profile / student→graduate→alumni relationship |
| Wellbeing | no counselling/medical foundation (sensitive-data ready) |
| Creator Economy | no creator profile/analytics domain |
| AI Platform | no provider-agnostic `Ai::` abstraction |
| UniFed Live | no `LiveStreamingService` abstraction |
| Blockchain verification | no `CredentialVerificationService` interface |

## 3. P0 priority (per mission recommendation) → chosen for this milestone
1. **GIS / Smart Campus** — new `campus` context (PostGIS-compatible schema, no infra dependency).
2. **Assignments / LMS** — new `lms` context (`Assignment`, `Submission`, `Rubric`), reusing `academic`/`assessment`.
3. **Administration** — admin controllers guarded by RBAC over existing contexts.
4. **Research Hub** — new `research` context.
5. **ActivityPub hardening** — close F-04/F-05/F-06 on existing `federation` context.

## 4. P1 (deferred to next milestone unless trivial)
Connect/messaging, expanded Discover (unified search abstraction), Marketplace, Alumni, Wellbeing, Creator tools.

## 5. P2 / Future (abstractions only, no infra)
AI `Ai::` service, `LiveStreamingService`, `CredentialVerificationService` (blockchain-ready), semantic search, GPS/indoor nav. Digital wallet & cloud infra explicitly out of scope.

## 6. Constraints honored
- No AWS/k8s/Terraform/GitOps/API-Gateway this task.
- Docker Compose staging stays runnable.
- PostGIS introduced via **optional** extension (migrations degrade gracefully; app works without enabling PostGIS on staging).
- All new features: authn + RBAC + ownership + validation + specs.

## 7. Test baseline (must stay green)
- Backend RSpec: **151/0** (current HEAD `d9d2572`).
- Frontend Vitest 7/7, Playwright 6/6.
- New contexts add model + service + request specs; P0 ships with regression coverage.
