# UniFed Nigeria — System Design Document (SDD)

**Version:** 1.0
**Companion to:** `docs/architecture/SAD.md`

---

## 1. System Context

UniFed serves three actor classes per instance: **Students**, **Staff/Lecturers**, **Administrators**,
plus external **federated instances**. A mobile-first web client (Next.js) and native apps (Flutter) consume
a JSON API behind an API gateway. The instance owns its PostgreSQL, Redis, and object storage.

## 2. Containers

| Container | Responsibility |
|---|---|
| Web Client | Next.js SPA/PWA; 5-tab unified UX |
| Mobile App | Flutter; same API contract |
| API Gateway / Ingress | Auth terminiation, routing, rate-limit |
| App Monolith | Academic, Records, StudentId, Identity, Admin contexts |
| Domain Services | Messaging, Media/Live, Search, Career, Marketplace, Research |
| PostgreSQL | System of record (per instance) |
| Redis | Cache, sessions, pub/sub, realtime |
| Object Storage | Avatars, media, documents |
| Event Bus | Domain events for federation + async |
| Federation Hub | ActivityPub inbox/outbox per instance |
| Blockchain Trust | Permissioned chain for credentials/audit |

## 3. Key Design Decisions

### 3.1 Domain-Driven Modular Monolith
Each bounded context is a Rails engine with explicit `namespace` (`Academic::`, `Records::`, `StudentId::`).
Cross-context references use explicit `class_name`. This keeps the slice testable and extraction-ready.

### 3.2 CQRS-lite for reads
Heavy read views (feed, summary, transcript) are served by dedicated query services (e.g.
`AcademicSummaryService`) rather than domain aggregates, to avoid N+1 and keep writes clean.

### 3.3 Federation Model
- Instance = ActivityPub **actor** (e.g. `@adun@unifed.ng`).
- Users are actors under the instance; posts/streams are objects addressed by URI.
- Inbox/outbox pattern; signed HTTP with HTTP Signatures.
- Credential/diploma verification anchored on-chain; content replicated only via ActivityPub.

### 3.4 Realtime
- Chat presence/typing: Redis pub/sub + WebSocket (ActionCable, later a Go gateway).
- Voice/video: WebRTC mesh for 1:1, SFU for groups (dedicated media service).
- Live: RTMP/WebRTC ingest → transcode → HLS; chat/polls/Q&A alongside.

### 3.5 Event-Driven
Domain events (`GradePublished`, `StudentVerified`, `PostCreated`) published to the bus; consumed by
federation (outbox) and analytics. Outbox pattern ensures at-least-once delivery without 2PC.

## 4. Component Design (per domain — target)

| Domain | Core components | Store |
|---|---|---|
| Academic / Records | Course, CourseOffering, GradeRecord, AcademicSummary, AcademicSummaryService | PG |
| StudentId | DigitalStudentId, IdIssuanceService, IdVerificationService, VerificationLog | PG + KMS |
| Federation | Actor, Note, Video, Inbox, Outbox, Webfinger, Signature | PG + bus |
| Social/Feed | Post, Story, ShortVideo, FeedAggregator, Poll, Trending | PG + OpenSearch |
| Messaging | Conversation, Message, Presence, CallSession | PG + Redis |
| Collaboration | Whiteboard, Doc, Calendar, StudyRoom, Meeting | PG + object store |
| Media/Live | Stream, Podcast, Recording, Replay, CaptionJob | S3 + transcode |
| Search | Indexer, SemanticSearch (embeddings) | OpenSearch |
| Career | Internship, Job, AlumniMentor, CV, InterviewPrep | PG |
| Marketplace | Listing, Order, (future Payment) | PG |
| Research | Publication, Dataset, Grant, Citation | PG + DOI |
| Creator | Channel, Analytics, Monetization(future) | PG |
| Wellbeing | Counselling, Medical, CheckIn, EmergencyContact | PG |
| Admin | UserMgmt, Moderation, Analytics, Notification | PG |
| BlockchainTrust | CredentialAnchor, Diploma, AuditRecord | Chain + PG mirror |
| AI | Assistant, Summarizer, Translator, Grader, Recommender, Moderator | PG + model API |

## 5. Data Flow Examples

**View academic summary:** Client → Gateway → Records context → `AcademicSummaryService#cumulative_summary`
(aggregates GradeRecords via Arel.sql) → JSON.

**Issue Digital Student ID:** Client → StudentId context → `IdIssuanceService#issue!` (signs JWT with KMS
key) → returns `{digital_id, token}` → QR rendered client-side.

**Federate a post:** PostCreated event → Outbox → signed ActivityPub POST → remote instance Inbox.

## 6. Scalability & Resilience

- Stateless app tier behind HPA (K8s).
- PG read replicas for feed/summary reads; federation writes stay on primary.
- Redis for hot caches (feed, presence, sessions).
- Circuit breakers on AI/model and blockchain calls; degrade gracefully (e.g. AI captions off).
- Multi-AZ RDS + automated backups + PITR.

## 7. Security Design

- OAuth2/OIDC login; MFA (TOTP/WebAuthn) for staff/admin.
- RBAC: Student / Lecturer / Admin roles per context.
- Zero Trust: every internal call authenticated; gateway enforces policy.
- NDPA: data residency `af-south-1`; consent for wellbeing/health data; right-to-erasure hooks.
- Audit log for identity/credential/admin actions.

## 8. API Contract

See `docs/api/openapi.yaml` (M1 endpoints implemented; target endpoints catalogued). All responses JSON;
errors use `{"error": "...", "details": [...]}`; auth via `Authorization: Bearer`.

## 9. Migration / Evolution

M1 monolith is the seed. Extraction order (roadmap): Federation+Social → Messaging+Live → Career+Marketplace
+Research → Admin+Wellbeing+Alumni → Blockchain+Security+AI → Scale/federation onboarding.
