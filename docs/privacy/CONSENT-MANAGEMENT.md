# UniFed Nigeria — Consent Management (DRAFT)

> **DRAFT. Status legend: DOCUMENTED POLICY / IMPLEMENTED TECHNICAL CONTROL / NOT YET IMPLEMENTED.
> No claim that policy equals legal compliance.**

---

## 1. System capability audit

| Capability | Status | Evidence |
|------------|--------|----------|
| Consent records stored | **IMPLEMENTED** | `identity_consent_records` table (granted, consent_version, granted_at) |
| Grant consent | **IMPLEMENTED** | `POST /api/v1/consent` sets granted + version + timestamp |
| Withdraw consent | **IMPLEMENTED** | `POST /api/v1/consent` with granted=false clears granted_at |
| Consent versioning | **IMPLEMENTED** | `consent_version` column + `config.x.consent_policy_version` |
| Privacy notice presented | **NOT YET IMPLEMENTED** | No privacy-notice endpoint/UI; see PRIVACY-NOTICE.md |
| Data access request | **PARTIAL** | Account-deletion request table exists; no export tooling |
| Correction request | **NOT YET IMPLEMENTED** | Users self-edit profile; no formal DSR workflow |
| Deletion request | **PARTIAL** | `account_deletion_requests` table (schema); workflow/erasure unverified |
| Restriction/objection | **NOT YET IMPLEMENTED** | Not in codebase |
| Data export | **NOT YET IMPLEMENTED** | No export endpoint |
| Retention enforcement | **NOT YET IMPLEMENTED** | Policy doc only; no purge jobs |
| Account closure | **PARTIAL** | Deletion-request table; no verified closure API |
| Audit logging | **PARTIAL** | Consent records timestamped; no centralized audit log reviewed |
| Breach escalation | **DOCUMENTED POLICY** | See INCIDENT-AND-DATA-BREACH-RESPONSE-PLAN.md |

## 2. Operational procedure (recommended)
1. Present privacy notice + consent at onboarding (to build).
2. Record consent with version + timestamp (done).
3. Honor withdrawal in real time (done).
4. Link consent state to data-processing modules (to build).
5. Retain consent records per retention policy (to build enforcement).

## 3. Gaps requiring build
Privacy-notice service + UI; DSR request intake + export/erasure tooling; retention purge jobs;
centralized audit log. All are **NOT YET IMPLEMENTED** and blocked on product + legal input.
