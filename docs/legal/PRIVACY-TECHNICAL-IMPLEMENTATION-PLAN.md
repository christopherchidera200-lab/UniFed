# Privacy Technical Implementation Plan (DRAFT)

> **DRAFT — engineering plan. Requires legal review for the policy decisions it supports.**
> Status reflects the audit of `security/strix-assessment`-era code on branch `legal/readiness`.

---

## 1. What was found

| Capability | Status in code | Evidence |
|---|---|---|
| Consent grant | **BROKEN** (500) | `consent_controller.rb` called undefined `grant!`; `User` lacked `consent_records` association |
| Consent withdrawal | Works (model) | `ConsentRecord#withdraw!` |
| Consent list | **BROKEN** (500) | depended on missing association |
| Consent timestamp | Partial (`created_at`, `withdrawn_at`) | no `granted_at` |
| Consent version | MISSING | no version column |
| Account deletion | MISSING (UI/flow) | only `status` enum + cascade destroy |
| Data export (portability) | MISSING | no endpoint/controller |
| Audit trail | Partial | consent ledger; access logs not centralised |
| Retention enforcement | MISSING | policy doc only |

## 2. What was fixed this turn (tested)

- **`backend/app/contexts/identity/app/models/identity/user.rb`**: added
  `has_many :consent_records, class_name: "Identity::ConsentRecord", dependent: :destroy`.
  Root cause of the 500s — the association was never declared.
- **`backend/app/controllers/api/v1/consent_controller.rb`**: rewrote `create` to set
  `granted`/`withdrawn_at` directly and **cast the boolean properly**
  (`ActiveModel::Type::Boolean`), so `granted: false` no longer silently grants.
- **`backend/spec/requests/consent_spec.rb`** (new): 6 examples covering grant, withdraw,
  re-grant, missing purpose, unauthenticated. **Result: 6/0.**
- Regression check: `identity_spec.rb` + `admin_spec.rb` = 22/0.

## 3. Still missing — recommend (do NOT implement blindly; confirm with product + legal)

| Item | Recommendation | Risk if skipped |
|---|---|---|
| Consent `version` column | Add `consent_version` + migrate; stamp on grant; show in privacy UI | Can't prove which policy version was accepted |
| `granted_at` timestamp | Add column; set on grant | Weak audit trail |
| Data export endpoint | `GET /api/v1/me/export` (NDPA portability) producing JSON/archive | DSR cannot be fulfilled in software |
| Account deletion workflow | Self-service delete → anonymise/ purge + cascade; notify federation | Erasure right unmet |
| Retention job | Recurring job per `DATA-RETENTION-POLICY-DRAFT.md` | Retention policy unenforced |
| Access audit log | Central table for authz/authn/admin actions | Breach response weak |

## 4. Guardrails for any future implementation

- All changes behind tests; preserve `dependent: :destroy` cascades.
- Never log secrets, passwords, tokens, or personal data.
- Deletion must coordinate federated copies (see `FEDERATION-POLICY-DRAFT.md`).
- Consent withdrawal must halt processing for that purpose immediately.

## 5. Verification evidence

- Consent request spec: `spec/requests/consent_spec.rb` → 6 examples, 0 failures.
- No existing test regressed (identity + admin suites green).
