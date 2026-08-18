# UniFed Nigeria — Software Features

> Source of truth: `README.md`, `backend/config/routes.rb`, `backend/app/contexts/*`, `frontend/src/pages/*`.
> Stack: Rails 8.1 modular monolith (16 bounded contexts) + Next.js (**Pages Router**, TypeScript, Tailwind). Federation via ActivityPub. Auth via OAuth2 / OIDC / MFA.

## 1. Federation (ActivityPub) — the core differentiator
UniFed is a **federated University OS**: each university runs its own instance and joins a network over ActivityPub (JSON-LD). No central owner of data.
- **WebFinger** discovery — `GET /.well-known/webfinger`
- **Actor inbox** (receive federated activities) — `POST /api/v1/federation/inbox`
- **Actor outbox** (published activities) — `GET /api/v1/federation/outbox`
- **JWKS + OIDC discovery** — `GET /.well-known/openid-configuration`, `GET /.well-known/jwks.json`
- Cross-university: users, content, moderation, policies, and infrastructure remain owned by each node.

## 2. Authentication & Identity
- **OAuth2 / OpenID Connect** token issuer — `POST /oauth/token`, `GET /oauth/userinfo`
- **Login / Register / Logout / Refresh** — `POST /api/v1/auth/{login,register,logout,refresh}`
- **MFA (TOTP)** enrollment + step-up verify — `POST /api/v1/auth/mfa/verify`, `POST /api/v1/mfa/totp/begin`, `/totp/confirm`, `GET /api/v1/mfa/devices`
- **Roles & permissions** — assign/revoke/audit — `POST /api/v1/roles/{assign,revoke}`, `GET /api/v1/roles/audit`
- **Consent (NDPA)** — `GET/POST /api/v1/consent`
- **Profile** — `GET /api/v1/profile` (authenticated user's own data; no password material leaked)

## 3. Academic Records & Digital Student ID
- **Student self-lookup** — `GET /api/v1/academic/me` (resolves current user's student identity)
- **Student records / summary / transcript** — `GET /api/v1/academic/students/:id/{records,summary}`, `POST .../transcript`
- **Transcript verification** — `POST /api/v1/transcript/verify` (tamper-evident)
- **Digital Student ID issue + verify** — `POST /api/v1/student-id/:student_id/issue`, `POST /api/v1/student-id/verify`
- University-scoped + role-checked authorization (verified clean in assessment).

## 4. Social / Feed
- **Feed timeline** — `GET /api/v1/feed`
- **Create post** — `POST /api/v1/feed/posts`
- **React / Comment** — `POST /api/v1/feed/posts/:id/{react,comments}`

## 5. Library
- **Browse resources** (public, node-scoped) — `GET /api/v1/library/resources`
- **Borrow / Return** — `POST /api/v1/library/{borrow,return}` (ownership-scoped — BOLA fixed)

## 6. Career Hub
- **Opportunities / Recommendations / Applications** — `GET /api/v1/career/{opportunities,recommendations,applications}`
- **Apply / Save job** — `POST /api/v1/career/opportunities/:id/{apply,save}`

## 7. Events & Calendar
- **Public events** — `GET /api/v1/calendar/events`
- **Events browse** (frontend) — `events.tsx`

## 8. SIWES (student industrial work experience)
- **Placement / Logs / Completion** — `POST /api/v1/siwes/{placement,logs}`, `GET /api/v1/siwes/completion`
- **Log verification** — `POST /api/v1/siwes/logs/:id/verify`

## 9. Assessments & Examinations
- **Record assessment** — `POST /api/v1/assessments/record`
- **Rollup** — `POST /api/v1/assessments/rollup`
- **Exam scheduling** — `GET /api/v1/examinations`

## 10. Catalog & Search
- **Course catalog / offerings** (public) — `GET /api/v1/catalog/{courses,offerings}`
- **Search** — `GET /api/v1/search`, `POST /api/v1/search/saved`
- **Discover** (frontend) — `discover.tsx`, `catalog.tsx`

## 11. Notifications
- **Unread list** — `GET /api/v1/notifications`
- **Mark read** (ownership-scoped) — `POST /api/v1/notifications/:id/read` (BOLA fixed)

## 12. Frontend (Next.js) surfaces
`index` (home) · `login` · `signup` · `profile` · `discover` · `catalog` · `create` (post) ·
`academic/records` · `career` · `events` · `library` · `connect` (federation) ·
`notifications`. Real authenticated user data throughout (no hardcoded identities).

## 13. Platform / Ops
- **Health** — `GET /api/v1/healthz`
- **Metrics** — `GET /metrics` (Prometheus)
- **Rate limiting** (proxy-aware client IP; XFF no longer trusted — fixed)
- **Security headers** (HSTS, CSP, XCTO, Referrer-Policy) — verified present
- **IaC** — Terraform (AWS), Kubernetes/Helm, Docker Compose; GitHub Actions CI
- **Observability direction** — Prometheus/Grafana/Loki/OpenTelemetry (planned)

## 14. Security posture (as of this milestone)
- **Fixed (code):** F-01 forgeable JWT secret (fail-closed), F-02 missing `aud` validation,
  F-03 rate-limit XFF trust, F-09 notifications BOLA, F-10 library loan BOLA.
- **Open:** federation signature/replay hardening (F-04/F-05/F-06), Docker/secret config
  (F-07/F-11/F-12), dev-dependency CVEs (F-13). See `docs/security/STRIX-*.md`.

## 15. Out of scope / planned
- Mobile (Flutter), WebRTC/LiveKit streaming, PostGIS/GIS, Go high-performance components —
  later phases per README roadmap.
