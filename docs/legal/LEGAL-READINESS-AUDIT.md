# UniFed Nigeria — Legal & IP Readiness Audit

**Document status:** `DRAFT — INTERNAL AUDIT` · Prepared by the engineering/documentation team
**Date of audit:** 2026-08-17
**Branch:** `legal/readiness`
**Scope:** Entire repository (`UniFed`) as of the audit commit.

> **NOT LEGAL ADVICE.** This is an engineering/compliance-readiness audit. Every item
> marked *"requires legal review"* must be reviewed by a qualified Nigerian lawyer (and,
> where indicated, a data-protection officer) before use. Creating these documents does
> **not** make UniFed legally compliant.

---

## 1. Audit method

- Full `git ls-files` enumeration of tracked files.
- Pattern search for privacy / terms / licence / consent / legal / policy / IP artifacts.
- Inspection of the `identity` context (consent, user, session, credential models) and the
  `api/v1/consent_controller.rb` endpoint.
- Contributor / commit-author extraction via `git shortlog -sne --all`.
- Review of existing `docs/security/*` (STRIX) and `docs/SECURITY.md`.

---

## 2. Existing documentation (found)

| Area | Artifact | Notes |
|---|---|---|
| Security policy | `docs/SECURITY.md` | Vulnerability reporting process. Not a legal/compliance policy. |
| Security audit | `docs/security/STRIX-EXECUTIVE-SUMMARY.md`, `STRIX-FINDINGS.md`, `STRIX-PENTEST-REPORT.md`, `STRIX-REMEDIATION-LOG.md`, `STRIX-REMEDIATION-PLAN.md`, `STRIX-TEST-MATRIX.md` | Security testing evidence. Relevant to due diligence (Phase 9). |
| Architecture / federation | `docs/architecture/ADR-0003-federation-activitypub.md`, `ADR-0005-adun-data-model.md` | Useful input for federation + data-ownership clauses. |
| Codebase inventory | `docs/CODEBASE-INVENTORY.md`, `CODEBASE-INVENTORY-AUDIT.md` | Useful for IP/third-party dependency audit. |

**Nothing** in the repository constitutes a privacy policy, terms of service, acceptable use
policy, community guideline, contributor licence agreement, IP assignment, or NDPA/Data
Protection documentation.

---

## 3. Missing documentation (must be created)

- [ ] Privacy Policy (NDPA 2023 aligned) — `PRIVACY-POLICY-DRAFT.md` (created)
- [ ] Terms of Service — `TERMS-OF-SERVICE-DRAFT.md` (created)
- [ ] Acceptable Use Policy — `ACCEPTABLE-USE-POLICY-DRAFT.md` (created)
- [ ] Community Guidelines — `COMMUNITY-GUIDELINES-DRAFT.md` (created)
- [ ] Federation Policy — `FEDERATION-POLICY-DRAFT.md` (created)
- [ ] University Pilot Partnership Agreement — `UNIVERSITY-PILOT-PARTNERSHIP-AGREEMENT-DRAFT.md` (created)
- [ ] Data Protection Readiness — `DATA-PROTECTION-READINESS.md` (created)
- [ ] Data Retention Policy — `DATA-RETENTION-POLICY-DRAFT.md` (created)
- [ ] Data Subject Request Procedure — `DATA-SUBJECT-REQUEST-PROCEDURE.md` (created)
- [ ] Data Breach Response Procedure — `DATA-BREACH-RESPONSE-PROCEDURE.md` (created)
- [ ] Data Processing Register — `DATA-PROCESSING-REGISTER.md` (created)
- [ ] IP Ownership Audit — `IP-OWNERSHIP-AUDIT.md` (created)
- [ ] IP Assignment Agreement — `INTELLECTUAL-PROPERTY-ASSIGNMENT-AGREEMENT-DRAFT.md` (created)
- [ ] Founder IP & Ownership Readiness — `FOUNDER-IP-AND-OWNERSHIP-READINESS.md` (created)
- [ ] Due-Diligence Legal Checklist — `DUE-DILIGENCE-LEGAL-CHECKLIST.md` (created)
- [ ] Legal-to-Technical Control Matrix — `LEGAL-TO-TECHNICAL-CONTROL-MATRIX.md` (created)
- [ ] Legal Readiness Report — `LEGAL-READINESS-REPORT.md` (created)
- [ ] Document index — `README.md` (created)
- [ ] **Repository LICENCE file** — *NOT created by this audit; see §6 / Phase 5.*
- [ ] **CONTRIBUTING.md / Contributor Licence Agreement** — *NOT created; see Phase 5.*

---

## 4. Incomplete documentation

- The `identity_consent_records` table exists (DDL in `db/schema/unifed_phase0.sql`) and a
  controller exists, but **the grant path is non-functional** (see §5 / Phase 4). The
  "consent" feature is only partially implemented and untested.
- `docs/SECURITY.md` exists but there is **no incident-response runbook tied to NDPA breach
  notification timelines** (created separately as `DATA-BREACH-RESPONSE-PROCEDURE.md`).
- No `Cookie` / tracking documentation — currently the app appears to use only
  session/authentication cookies; flagged as *future* if analytics/tracking are added.

---

## 5. Potential conflicts

- **Federation vs. data ownership.** ActivityPub federation inherently copies user-generated
  content and actor metadata across instances. The pilot agreement and federation policy must
  make explicit that federation does **not** transfer ownership of university/student data. The
  code currently federates actor documents; the legal boundary is not yet documented
  (see `FEDERATION-POLICY-DRAFT.md`).
- **Open-source components vs. proprietary claim.** The codebase uses third-party gems
  (Rails, etc.) and possibly OSS-licensed libraries. A blanket "UniFed owns all IP" claim would
  conflict with OSS licence obligations (attribution, copyleft). The IP audit flags this.
- **Consent model vs. controller bug.** The model supports withdrawal (`withdrawn_at`); the
  controller cannot record a *grant* for new purposes (NoMethodError on `grant!`). This is a
  functional conflict that must be fixed before the consent documentation can be honoured.

---

## 6. Documents requiring professional legal review

ALL drafts in §3 marked `DRAFT` require review by a qualified Nigerian lawyer. Highest priority:

1. `UNIVERSITY-PILOT-PARTNERSHIP-AGREEMENT-DRAFT.md` — before any approach to ADUN.
2. `PRIVACY-POLICY-DRAFT.md` + `DATA-PROTECTION-READINESS.md` — NDPA 2023 alignment.
3. `INTELLECTUAL-PROPERTY-ASSIGNMENT-AGREEMENT-DRAFT.md` — investor/grant due diligence.
4. **Repository LICENCE selection** (MIT/Apache-2.0/EUPL/etc.) and whether a CLA is required —
   this is a legal + business decision, not an engineering one.

---

## 7. Technical controls required to support the documents

| Document | Control needed | Current status | Where |
|---|---|---|---|
| Privacy Policy | Consent grant + version + timestamp | **BROKEN** (grant path) | `identity/consent_record.rb`, `api/v1/consent_controller.rb` |
| Data Subject Request | Data export endpoint | MISSING | no route/controller |
| Account deletion | Account deletion / anonymisation workflow | MISSING (only `status` enum + cascade destroy) | `identity/user.rb` |
| Audit trail | Consent + access audit logs | PARTIAL (consent ledger; access logs TBD) | `identity_consent_records` |
| Breach response | Incident runbook + 72h NDPA notification | MISSING (process doc only) | `DATA-BREACH-RESPONSE-PROCEDURE.md` |
| Retention | Retention enforcement job | MISSING (policy doc only) | `DATA-RETENTION-POLICY-DRAFT.md` |

See `LEGAL-TO-TECHNICAL-CONTROL-MATRIX.md` for the full mapping.

---

## 8. IP / contributor findings (summary; full in Phase 5)

- **No LICENCE file** in the repository root or anywhere.
- **No SPDX / copyright headers** in source files.
- **No CONTRIBUTING.md, no CLA, no DCO.**
- Commit authors are a mix of:
  - `UniFed Engineering <eng@unifed.ng>` (65 commits)
  - `Hermes Agent <agent@unifed.ng>` (15 commits)
  - `Christopher Chidera <christopherchidera200@email.com>` (7 commits)
  - `chidera christopher <christopherchidera200@gmail.com>` (3 commits)
  - `CHIDERA OKPALANWOLISA <christopherchidera200@gmail.com>` (1 commit)
  - `CloudIntel <dev@cloudintel.local>` (2 commits)
- Personal Gmail identities with **no assignment** to any UniFed entity → IP ownership cannot be
  assumed. This is a **due-diligence blocker** until clarified (Phase 5/6/9).

---

## 9. Conclusion

The repository is **functionally advanced** (staging milestone, security-tested) but has
**near-zero legal-readiness artifacts**. The three advisor-flagged areas (pilot agreement, data
protection, IP ownership) were entirely undocumented. This workstream supplies DRAFT templates
and an honest technical control matrix. Legal compliance is **not** claimed and requires counsel.
