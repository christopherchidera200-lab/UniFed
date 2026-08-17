# UniFed Nigeria — Legal Readiness Report (DRAFT)

> **DRAFT — internal report. NOT legal advice. Legal readiness is not legal compliance.**

---

## 1. Executive summary

UniFed has reached a functional staging milestone with a security-tested codebase, but had
**near-zero legal-readiness documentation**. This workstream (branch `legal/readiness`) supplies
19 draft documents covering the three advisor-flagged areas — pilot agreement, data protection, and
IP ownership — plus supporting policies, a due-diligence checklist, and an honest technical
control matrix. A latent **consent bug** was found and fixed with tests.

## 2. Current legal-readiness level

**LOW → emerging.** Documentation now exists as DRAFT; nothing is legally reviewed or compliant.
Top gaps: missing repo licence, unassigned personal contributions, no executed pilot agreement,
DPIA not performed.

## 3. Documents created (19)

All under `docs/legal/` — see `README.md` index. Audit, pilot agreement, data-protection readiness,
privacy/retention/DSR/breach/register, IP audit, IP assignment, founder readiness, ToS, AUP,
community guidelines, federation policy, due-diligence checklist, privacy technical plan, control
matrix, this report.

## 4. Documents requiring legal review

All documents marked `NEEDS LEGAL REVIEW` in `README.md` (16 of 19). Highest priority: pilot
agreement, privacy policy + data-protection readiness, IP assignment, and **licence selection**.

## 5. Missing information

- UniFed legal entity name/registration.
- Founder identities, equity, founder agreements.
- Pilot university's full legal name/address (ADUN) — placeholder used per context.
- Sub-processor list (cloud host, email).
- DPIA outcome.
- Consent version/timestamp schema decision.

## 6. Technical controls implemented (this turn)

- Fixed consent grant/withdraw (was 500 due to missing `consent_records` association + broken
  `grant!` call + uncast boolean). Added `has_many :consent_records` to `User`; corrected controller
  boolean casting. New spec `spec/requests/consent_spec.rb` → **6/0**. Regression: identity+admin
  suites **22/0**.

## 7. Technical controls still missing

- Consent `version` + `granted_at` columns.
- Data-export (portability) endpoint.
- Account-deletion / anonymisation workflow.
- Retention-enforcement job.
- Central access audit log.
- Repository `LICENSE` file.

## 8. IP ownership risks

- **HIGH:** no `LICENSE` file (default all-rights-reserved); personal-Gmail contributor with no
  assignment.
- **MEDIUM:** AI-generated code (Hermes Agent) provenance undocumented; third-party licence
  inventory not produced.

## 9. Data protection risks

- Controller/processor roles unconfirmed per data category.
- DPIA not done (required pre-pilot for student data).
- Consent versioning absent; deletion/export unsupported in code.
- Federated-data erasure cannot fully purge already-propagated copies.

## 10. Pilot agreement readiness

Draft template complete with 41 clauses + 5 appendices. **Not executable** until UniFed legal
entity + ADUN legal details are filled and counsel reviews.

## 11. Investor due-diligence readiness

Checklist in `DUE-DILIGENCE-LEGAL-CHECKLIST.md`. Blockers: entity, cap table, IP assignments,
licence, pilot agreement, DPIA.

## 12. Grant due-diligence readiness

Same blockers as investor, plus explicit data-protection/NDPA evidence and security audit
(`docs/security/STRIX-*`) already available as a strength.

## 13. Recommended next steps

1. Form/confirm UniFed legal entity.
2. Engage a qualified Nigerian lawyer to review the `NEEDS LEGAL REVIEW` set.
3. Execute founder + contributor IP assignments; add `LICENSE`.
4. Complete DPIA; finalise sub-processor DPAs.
5. Fill pilot agreement with ADUN facts; obtain signature before go-live.
6. Implement missing technical controls (consent version, export, deletion, retention job).
7. Re-run full backend suite after any further code change.

---

*Prepared by the engineering/documentation team. All drafts require qualified legal review before
use. This report does not claim compliance.*
