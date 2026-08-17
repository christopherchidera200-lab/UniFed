# Data Retention Policy (DRAFT)

> **DRAFT — REQUIRES REVIEW BY QUALIFIED NIGERIAN DATA PROTECTION / PRIVACY COUNSEL**
> Retention periods below are PROPOSALS. The University (as controller) sets final periods. This
> document alone does not constitute compliance.

---

## 1. Purpose

Define retention periods and deletion rules for personal data processed by UniFed instances.

## 2. Principles

- Data is kept only as long as necessary for the purpose or a legal obligation.
- Academic records follow the University's retention schedule (often long/permanent for transcripts).
- Deletion is certifiable; federated copies handled per the federation policy.

## 3. Retention schedule (PROPOSED — confirm with University + counsel)

| Data | Proposed retention | Basis |
|---|---|---|
| Account / identity | Life of account + [PERIOD] after deletion | Operational |
| Credentials (hashed) | Until credential revoked/deleted | Security |
| MFA devices | Until removed | Security |
| Sessions / tokens | Until expiry / logout | Security |
| Consent records | Duration of processing + [PERIOD] | NDPA accountability |
| Academic records | Per University policy (transcripts long-term) | Education law |
| Content / posts | Until deleted by user / University | Service |
| Messages | [PERIOD] or until deletion | Service |
| Audit logs | [PERIOD, e.g., 12 months] | Security/accountability |
| Federated actor data | Until defederation / withdrawal | Federation policy |

## 4. Retention enforcement

A scheduled job should purge expired records per the schedule. **STATUS: MISSING in code** —
see `LEGAL-TO-TECHNICAL-CONTROL-MATRIX.md`. Until implemented, retention is policy-only.

## 5. Deletion & return

On account deletion or termination, University Data is returned/ deleted per the pilot agreement
Clause 20 and `DATA-SUBJECT-REQUEST-PROCEDURE.md`.

## 6. Legal holds

Records under legal hold are excluded from automated deletion.

## 7. Review

Retention schedule reviewed [ANNUALLY] with the University and counsel.
