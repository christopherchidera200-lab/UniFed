# UniFed Nigeria — Data Protection Impact Assessment (DPIA) (DRAFT)

> **DRAFT — prepared from the actual implementation. NOT a legal compliance determination; where
> legal interpretation is required, marked LEGAL REVIEW REQUIRED. No claim of NDPA compliance is
> made. Processing is split into CURRENT (implemented) and PLANNED (not implemented).**

---

## 1. Processing description
UniFed is a federated digital-university operating system. It processes personal data of students,
lecturers, administrators, employers, and researchers across academic, identity, social, career,
library, events, and notification functions, with optional cross-university federation via
ActivityPub.

## 2. Purpose
- Provide authenticated access to university services (academic records, student IDs, library, career).
- Enable communication and federation between participating universities.
- (Planned) AI-assisted study/career features; analytics; GIS campus services.

## 3. Categories of data
**CURRENT:** identity (email, name, role, university), profile (bio, avatar), academic records
(grades, enrollments), student IDs, notifications, social posts, follows, library loans, career
opportunities applied to, events. **PLANNED:** location/GIS, AI inference, analytics events,
employer PII, research datasets.

## 4. Categories of data subjects
Students, lecturers/staff, administrators, employers, researchers, (planned) guardians.

## 5. Data flows
Browser → Next.js → Rails API (JWT auth) → PostgreSQL/Redis. Federation: signed ActivityPub
HTTP Signatures between nodes. **CURRENT federation key fetch is HTTPS-only with an SSRF guard
added this engagement (blocks private/link-local/metadata IPs).**

## 6. Data storage
PostgreSQL (primary), Redis (sessions/cache), object storage (planned: media). Secrets via
deployment secrets (fail-closed since hardening). DB/Redis NOT published to host network
(F-11 fixed).

## 7. Data sharing
- **Intra-node:** university-scoped, role-authorized.
- **Federation:** only public/university-consented actors/activities per ActivityPub; signature-verified.
- **Third parties:** none in CURRENT processing beyond infra providers (planned: email/SMS, CDN, AI API).
- **LEGAL REVIEW REQUIRED:** cross-border transfer implications of federation (NDPA §) and foreign AI/cloud processors.

## 8. Federation flows
Actors, follows, posts, deletes. Replay-protected (F-06). Follow edges persisted; deletes tombstoned (F-05).
**PLANNED:** media/avatar federation, full webfinger resolution (currently stubbed).

## 9. Third-party processors
**CURRENT:** none beyond hosting (Docker/local). **PLANNED:** AWS (compute/DB/object), email/SMS,
AI API, analytics, CDN. Each requires a documented processor agreement + DPA.

## 10. Retention
See `DATA-RETENTION-POLICY.md`. Most categories have a **proposed** period; **few are technically
enforced** (consent records are timestamped; most others have no purge job). LEGAL REVIEW REQUIRED
for final periods (NDPA storage-limitation principle).

## 11. Security controls (CURRENT, verified)
Auth on all API routes; university/role authorization; BOLA fixes (F-09/F-10); fail-closed JWT
secret (F-01) + aud pinning (F-02); rate-limit spoof-proofing (F-03); HSTS/CSP headers; Brakeman
0 warnings; federation SSRF/follow/replay hardening (F-04/05/06); secrets no longer committed (F-07);
DB/Redis not host-exposed (F-11); fail-closed SECRET_KEY_BASE (F-12).

## 12. Privacy risks
R-1 Forgeable tokens → mass data exposure (mitigated F-01). R-2 BOLA cross-user access (mitigated).
R-3 Federation spoofing (mitigated F-04/05/06). R-4 Data over-retention (PARTIAL — policy exists,
enforcement missing). R-5 No DSR automation (PARTIAL). R-6 Cross-border/processor risk (PLANNED,
unassessed). R-7 Consent withdrawal gaps (PARTIAL — consent API exists; notice/DSR workflow missing).

## 13. Risk severity
F-01/F-02/F-03/F-04/F-05/F-06/F-09/F-10/F-11/F-12: **LOW residual** (controls verified).
R-04/R-05/R-07: **MEDIUM** (policy without full enforcement). R-06: **MEDIUM-HIGH** (unassessed).

## 14. Mitigations
- Enforce retention via scheduled jobs (to build).
- Implement DSR export/delete tooling (to build).
- Publish privacy notice + consent UX (to build).
- Execute DPAs with each planned processor (to build). LEGAL REVIEW REQUIRED.

## 15. Residual risks
Retention/DSR automation gaps; unassessed cross-border/processor risk; no external pen-test.

## 16. Data subject rights
Access, correction, deletion, objection, withdrawal of consent, data portability.
**CURRENT support:** consent grant/withdraw (API); account deletion request table (schema only,
unverified). **GAPS:** self-service export, automated erasure, request tracking UI.

## 17. Breach response
See `docs/security/INCIDENT-AND-DATA-BREACH-RESPONSE-PLAN.md`. Owner to be appointed.

## 18. Governance
No appointed DPO/CISO; no NDPC registration evidence. LEGAL REVIEW REQUIRED; owner to be appointed.

## 19. Review schedule
Re-review at: (a) ADUN pilot launch; (b) each new context (GIS/AI/media) before enablement;
(c) annually. **LEGAL REVIEW REQUIRED before representing NDPA alignment.**
