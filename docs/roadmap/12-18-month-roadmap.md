# UniFed Nigeria — 12–18 Month Development Roadmap

**Baseline:** M1 complete — Academic Records + Digital Student ID (backend ✅, minimal frontend ✅,
Terraform ✅, CI green ✅). ADUN is the pilot instance.

This roadmap delivers the full "Complete Feature Requirements" spec in phases. Each phase ends shippable.

---

## Phase 0 — Foundation Hardening (Month 0–2)
**Goal:** production-grade base before scaling features.
- Deploy M1 to AWS (EKS) via GitOps (ArgoCD); wire RDS/Redis/S3/secrets.
- Replace broken local Ruby tooling in CI; make `rails db:migrate` the deploy schema step.
- Auth: OAuth2/OIDC + MFA (TOTP/WebAuthn) for staff/admin; RBAC roles.
- Observability: OTel + Prometheus + Grafana; SLOs per domain.
- API gateway + rate-limiting + secure headers.
- NDPA compliance pass: data residency, consent, audit logging.
- **Exit:** M1 live on ADUN with real auth, monitoring, deploys.

## Phase 1 — Federation & Social Core (Month 2–5)
- ActivityPub engine: actors, inbox/outbox, Webfinger, HTTP Signatures.
- Social: posts, stories, short videos, polls, comments, reactions, feeds.
- Discovery: universal search + semantic AI search (pgvector + embeddings).
- Profile: expand to full Profile tab (bio, skills, portfolio, social).
- **Exit:** ADUN users post/federate; cross-instance follows work.

## Phase 2 — Connect: Comms & Collaboration (Month 4–8)
- Messaging: 1:1/group chat, voice/video (WebRTC mesh + SFU), voice notes, files, reactions, receipts.
- Collaboration: whiteboard, shared docs/notes, shared code editor, markdown/LaTeX, calendar,
  study rooms, Pomodoro, attendance.
- Presence statuses (In Lecture / Studying / …).
- **Exit:** UniFed replaces ad-hoc student comms at ADUN.

## Phase 3 — UniFed Live & Media (Month 6–9)
- Streaming service (Go): ingest, transcode, HLS, recordings/replay.
- Live chat/polls/Q&A/reactions; AI captions + translation.
- Podcasts, University TV, conferences, lectures.
- **Exit:** Convocations/matriculations streamed in-app.

## Phase 4 — Careers, Marketplace, Research, Creator (Month 8–12)
- Career Hub: internships, jobs, alumni mentoring, CV builder, AI resume review, interview prep.
- Marketplace: listings, orders (digital payments = future).
- Research Hub: groups, publications, datasets, grants, DOI, citations.
- Creator Economy: channels, analytics, monetization (future).
- **Exit:** Full student-life loop operational.

## Phase 5 — Admin, Wellbeing, Alumni, Smart Campus (Month 10–14)
- Admin Portal: manage students/staff/faculties/depts/courses/results/assignments/timetables/
  events/announcements/verification/security/analytics/moderation.
- Wellbeing: counselling/medical appointments, anonymous check-ins, emergency contacts, SOS.
- Alumni: communities, mentorship, donations, recruitment.
- Smart Campus: maps, GPS navigation, QR wayfinding, building directory, shuttle routes,
  emergency evacuation (indoor nav = future).
- **Exit:** Institution fully administered in-app.

## Phase 6 — AI Platform & Blockchain Trust (Month 12–16)
- AI services: assistant, summarizer, translator, study/research helper, rubric grading,
  recommendations, moderation, captions, flashcards, quizzes.
- Consortium blockchain: permissioned chain for identity/credentials/diplomas/transcript/
  credit-transfer/governance/audit anchors; PG mirror.
- **Exit:** Verifiable credentials + AI assist across platform.

## Phase 7 — Scale, Federation Onboarding & Polish (Month 14–18)
- Multi-instance onboarding kit: new universities spin independent instances, federate to ADUN.
- Performance: read replicas, caching, partitioning at scale; load/soak testing.
- Security: Zero Trust, DDoS protection, anti-spam, pen-test, audit.
- UI/UX: full 5-tab unified app, design-system completion, a11y certification.
- **Exit:** Platform serves millions; N universities federated.

---

## Resource model (indicative)
- **Phase 0–1:** 2 backend + 1 frontend + 1 cloud/DevOps.
- **Phase 2–4:** +2 backend (realtime/go) + 1 mobile (Flutter) + 1 QA.
- **Phase 5–7:** +1 security + 1 SRE + 1 AI/ML + design.
- Mobile (Flutter) tracks web from Phase 2.

## Key risks & mitigations
- **Federation interoperability:** adopt Mastodon-compatible vocabulary early; test cross-instance.
- **Realtime at scale:** extract messaging/live to Go services before load grows.
- **AI cost/latency:** model routing + caching; degrade gracefully.
- **NDPA:** residency + consent enforced from Phase 0, not retrofitted.
- **Scope:** each phase shippable; defer "future" items explicitly.

## Definition of Done (full spec)
All 13+ domains implemented per requirements; 5-tab unified UX; federation live; AI + blockchain trust
operational; security/observability production-grade; ≥1 additional university federated.
