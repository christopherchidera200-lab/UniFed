# UniFed Nigeria — Data Subject Request (DSR) Procedure (DRAFT)

> **DRAFT — operational procedure. Capabilities marked IMPLEMENTED only where present in code.
> No feature is claimed beyond what exists.**

---

## 1. DSR workflow
```
Request received (channel: support / in-app)
  → Identity verification (must match account holder)
  → Classification (access / correction / deletion / objection / portability)
  → Data discovery (query relevant contexts)
  → Review (privacy officer; LEGAL REVIEW REQUIRED for deletions affecting academic records)
  → Response (within statutory period — LEGAL REVIEW REQUIRED for the exact deadline)
  → Audit record (log request + action)
  → Closure
```

## 2. Automation vs manual (CURRENT)
| Step | Automation | Status |
|------|------------|--------|
| Intake | None | **NOT YET IMPLEMENTED** (email/manual) |
| Identity verification | None | **NOT YET IMPLEMENTED** (manual) |
| Access / export | None | **NOT YET IMPLEMENTED** (no export endpoint) |
| Correction | Partial (self-service profile edit) | **IMPLEMENTED (profile only)** |
| Deletion | Request table exists (`account_deletion_requests`) | **PARTIAL** — no verified erasure job |
| Audit record | None centralized | **NOT YET IMPLEMENTED** |
| Closure | Manual | **NOT YET IMPLEMENTED** |

## 3. What can be automated now
- Consent withdrawal (live, implemented).
- Profile self-correction (implemented).
- Deletion request capture (schema present).

## 4. What requires build
- DSR intake portal + identity verification.
- Data export endpoint (portability).
- Erasure job across contexts (respecting university retention for academic records).
- Audit log of DSRs.

## 5. Statutory timeline
**LEGAL REVIEW REQUIRED** — NDPA response timelines must be confirmed by counsel; do not assert a
number here without legal sign-off.
