# Data Protection Readiness — Nigeria Data Protection Act (NDPA) 2023

> **DRAFT — REQUIRES REVIEW BY QUALIFIED NIGERIAN DATA PROTECTION / PRIVACY COUNSEL**
> This document maps UniFed's data processing to NDPA 2023 concepts. It is an engineering/
> readiness assessment, **not** a compliance certification. The existence of this document does
> **not** mean UniFed is NDPA-compliant.

---

## 1. Legal basis & context

- NDPA 2023 establishes the Nigeria Data Protection Commission (NDPC) and data-protection
  obligations for controllers/processors of personal data in Nigeria.
- A **Data Protection Impact Assessment (DPIA)** is expected for high-risk processing (education,
  children/students, special categories). University + student data is high-risk → DPIA required
  before pilot go-live (*legal + DPO action*).
- The controller/processor classification per data category is a **legal question requiring
  confirmation** (see §4). Do not assume UniFed is merely a processor.

## 2. Data categories processed

| Category | Examples | Sensitivity |
|---|---|---|
| Student identity | name, matric, DOB, gender, contact | High |
| Academic records | results, transcripts, assessments | High |
| Digital student identity | account, credentials, MFA | High |
| Student profiles | bio, avatar, interests | Medium |
| Staff/lecturer data | name, role, contact, qualifications | High |
| Administrator data | admin accounts, actions | High |
| Employer/career data | employer contacts, job posts, CVs | Medium |
| Federated-user data | actor metadata from other instances | Medium–High |
| Authentication data | password hashes, sessions, tokens | High |
| Device/session data | IP, UA, session IDs | Medium |
| Audit logs | access, consent, admin actions | Medium |
| Communications | messages, comments, mentions | Medium |
| Content | posts, assignments, events, library | Medium |
| Location/GIS | *not currently collected* | N/A (future) |
| Research data | *future* | TBD |
| Marketplace data | *future* | N/A (future) |

## 3. Categories of users (data subjects)

Students · Staff/Lecturers · Administrators · Employers (career) · Federated users (other
instances) · Visitors (where applicable).

## 4. Controller / processor roles — LEGAL QUESTION

| Data | Likely controller | Likely processor | Status |
|---|---|---|---|
| University academic/student data | University | UniFed (on behalf) | **Confirm with counsel** |
| UniFed platform/account metadata | UniFed | — | Confirm |
| Federated actor data | Originating instance | Receiving instance | Confirm per federation policy |

## 5. Data lifecycle (expected)

**Collection** → obtain consent/legal basis; minimise; inform via Privacy Policy.
**Processing** → only for stated purposes; honour consent withdrawal.
**Storage** → encrypted at rest/in transit; access-controlled; per `DATA-RETENTION-POLICY-DRAFT.md`.
**Federation/sharing** → only within configured federation scope (Appendix E of pilot agreement).
**Retention** → enforce periods; review.
**Deletion** → on request/termination; certify; address federated copies.

## 6. University vs UniFed responsibilities

- University: lawful basis, consent, DPIA, data-subject requests handling, retention decisions.
- UniFed: technical/organisational measures, breach cooperation, deletion/return tooling.

## 7. Third-party processors

- Cloud hosting (e.g., [CLOUD PROVIDER] — *to be completed*).
- Email/SMS providers, analytics (*if added*).
- Each requires a data-processing addendum (DPA) — **not yet documented**; create before pilot.

## 8. Cross-university & cross-border

- Federation transfers data between Nigerian university instances → assess whether cross-border.
- If any data leaves Nigeria (hosting/processor abroad), additional NDPC conditions apply.
- *Action: document hosting region and sub-processors.*

## 9. User rights (NDPA)

Access · Rectification · Erasure · Restriction · Portability · Objection · Withdraw consent.
See `DATA-SUBJECT-REQUEST-PROCEDURE.md` for the workflow (currently **partially supported** in
code — consent withdrawal exists; export/deletion endpoints MISSING).

## 10. Consent requirements

- Consent must be specific, informed, freely given, and withdrawable.
- The `identity_consent_records` ledger supports purpose-scoped consent + withdrawal, **but the
  grant path is currently broken** (Phase 4 fix required) and lacks a consent *version* and
  *grant timestamp*.

## 11. Security safeguards

See `LEGAL-TO-TECHNICAL-CONTROL-MATRIX.md` and the STRIX remediation log. Summary: encryption in
transit, hashed credentials, RBAC, MFA, SSRF guards, signature verification, token secret isolation.

## 12. Breach / incident process

See `DATA-BREACH-RESPONSE-PROCEDURE.md` (NDPA 72-hour notification target).

## 13. Retention & deletion

See `DATA-RETENTION-POLICY-DRAFT.md`. Enforcement job is **MISSING** in code.

## 14. Gaps requiring action (engineering)

- Fix consent grant bug; add consent `version` + `granted_at`.
- Implement data-export (portability) endpoint.
- Implement account-deletion / anonymisation workflow.
- Implement retention-enforcement job.
- Build access audit log table if not present.

## 15. Status

`NEEDS INFORMATION` + `NEEDS LEGAL REVIEW`. Not compliant merely by documentation.
