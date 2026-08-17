# Legal-to-Technical Control Matrix (DRAFT)

> **DRAFT — engineering mapping. Status is current as of branch `legal/readiness`.**
> Maps legal requirements to technical controls, code location, status, and required action.

| Legal Requirement | Technical Control | Repository Location | Current Status | Required Action | Test | Evidence |
|---|---|---|---|---|---|---|
| Consent capture (NDPA) | Consent grant/withdraw API | `app/controllers/api/v1/consent_controller.rb`, `models/identity/consent_record.rb` | FIXED (was 500) | None (verify) | `spec/requests/consent_spec.rb` | 6/0 ✅ |
| Consent association | `has_many :consent_records` | `models/identity/user.rb` | FIXED | None | consent_spec | 6/0 ✅ |
| Consent timestamp | `created_at`/`withdrawn_at`; no `granted_at` | `consent_record.rb` | PARTIAL | Add `granted_at` + migration | spec | DDL in `db/schema/unifed_phase0.sql` |
| Consent version | none | — | MISSING | Add `consent_version` column | spec | — |
| Data export (portability) | export endpoint | none | MISSING | Build `GET /api/v1/me/export` | spec | — |
| Account deletion | `status` enum + cascade destroy | `models/identity/user.rb` | PARTIAL | Self-service delete workflow | spec | — |
| Access audit trail | consent ledger; no central authz log | `consent_record.rb` | PARTIAL | Add audit log table | spec | — |
| Retention enforcement | policy doc only | — | MISSING | Recurring retention job | spec | `DATA-RETENTION-POLICY-DRAFT.md` |
| Breach detection/notify | runbook | `DATA-BREACH-RESPONSE-PROCEDURE.md` | PROCESS ONLY | Wire monitoring → runbook | — | — |
| Encryption in transit | TLS (deploy) | `docker-compose*.yml`, infra | DEPLOY-DEP | Verify in prod | — | — |
| Secret isolation (vuln-0004) | `TOKEN_SERVICE_SECRET` | `token_service.rb` | DONE (STRIX) | None | `token_service_*_spec` | 7/0 ✅ |
| SSRF guard (vuln-0001/2) | `SsrfGuard` | `federation/ssrf_guard.rb` | DONE (STRIX) | None | `ssrf_guard_spec` | 4/0 ✅ |
| Signature verify (vuln-0003) | header set + date skew | `signature_verifier.rb` | DONE (STRIX) | None | `signature_verifier_spec` | 6/0 ✅ |
| RBAC / access control | roles/permissions | `role_assignment`, `base_controller` | DONE | None | `admin_spec` | 22/0 ✅ |
| Licence / IP notice | none | — | MISSING | Add `LICENSE` + headers | — | `IP-OWNERSHIP-AUDIT.md` |
| Federation ownership boundary | signature verify + scope | `federation/*` | DONE (code) | Document + policy | fed specs | `FEDERATION-POLICY-DRAFT.md` |

Legend: ✅ tested green this turn; DONE = implemented (STRIX); MISSING/PARTIAL = action required; PROCESS ONLY = document exists, no code.

> STRIX test counts are from the security branch verification; re-run on this branch if needed.
