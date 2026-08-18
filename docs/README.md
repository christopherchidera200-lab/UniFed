# UniFed Nigeria — Documentation Index

> Last curated: 2026-08-17. This folder was cleaned of superseded staging/DevOps
> snapshots and duplicate inventories. Files marked **DRAFT** / **NEEDS LEGAL REVIEW**
> are working documents, not policy.

## How to read this folder
- **Architecture & planning** are the long-lived source of truth.
- **Security / Privacy / Legal / Compliance / Readiness** are evidence sets from the
  respective workstreams (dated when generated).
- **Status snapshots** (`CODEBASE-INVENTORY.md`, `COVERAGE.md`, `FEATURES.md`) are
  refreshed as the build evolves — treat them as point-in-time, not gospel.

## Architecture & Planning
| Path | What |
|---|---|
| `architecture/ADR-0001-platform-constitution.md` | Platform constitution & repo strategy |
| `architecture/ADR-0002-modular-monolith.md` | Modular monolith decision |
| `architecture/ADR-0003-federation-activitypub.md` | ActivityPub federation |
| `architecture/ADR-0004-authentication.md` | OIDC/MFA auth architecture |
| `architecture/ADR-0005-adun-data-model.md` | ADUN academic data model |
| `architecture/SAD.md` | Software Architecture Description |
| `architecture/system-context.md` | System context / boundaries |
| `architecture/ROADMAP.md` | High-level milestone roadmap (M1–M5) |
| `roadmap/12-18-month-roadmap.md` | Detailed phased delivery plan |
| `api/API_SPECIFICATION.md`, `api/openapi-slice1.yaml` | API spec (slice 1) |

## Design
| Path | What |
|---|---|
| `design/README.md` | Design workstream index + debunked assumptions |
| `design/UniFed-Frontend-Design-Lab.html` | Frontend design lab artifact (IA, color, components) |
| `design/SDD.md` | Software Design Description |
| `design/DATABASE_SCHEMA.md` | Database schema reference |
| `design/UIUX_DESIGN_SYSTEM.md` | UI/UX design system |

## Security (STRIX assessment)
`security/STRIX-EXECUTIVE-SUMMARY.md` · `STRIX-PENTEST-REPORT.md` · `STRIX-FINDINGS.md` ·
`STRIX-REMEDIATION-PLAN.md` · `STRIX-REMEDIATION-REGISTER.md` · `STRIX-TEST-MATRIX.md` ·
`SECURITY-EVIDENCE-INDEX.md` · `INCIDENT-AND-DATA-BREACH-RESPONSE-PLAN.md` (DRAFT).
Top-level `SECURITY.md` is the public security policy.

## Privacy (NDPA)
`privacy/PRIVACY-NOTICE.md` · `DPIA.md` · `CONSENT-MANAGEMENT.md` ·
`DATA-RETENTION-POLICY.md` · `DATA-SUBJECT-REQUEST-PROCEDURE.md` ·
`DATA-BREACH-RESPONSE-PLAN.md` (DRAFT).

## Legal & IP
`legal/ENTITY-AND-OWNERSHIP-REGISTER.md` · `IP-OWNERSHIP-REGISTER.md` ·
`LICENSE-DECISION.md` (all-rights-reserved; no LICENSE file — due-diligence item) ·
`legal/templates/*` (founder/contributor/contractor/invention IP assignment drafts).

## Compliance
`compliance/READINESS-GAP-AUDIT.md` — NDPA/security readiness gap audit.

## Impact
`impact/UNIFED-IMPACT-MEASUREMENT-FRAMEWORK.md` · `PILOT-BASELINE-AND-EVALUATION-PLAN.md`.

## Readiness (workstream closure)
`readiness/READINESS-CLOSURE-REPORT.md` · `USER-INFORMATION-REQUIRED.md` ·
`LEGAL-SECURITY-IMPACT-READINESS.md`.

## Status snapshots
`CODEBASE-INVENTORY.md` (canonical live inventory) · `COVERAGE.md` (feature gap matrix) ·
`FEATURES.md` (feature catalogue) · `FEATURE-GAP-AUDIT.md` · `FEATURE-IMPLEMENTATION-REPORT.md`.

## Audit artifact
`audit-report-one-page.pdf` / `audit-report-one-page.html` — one-page audit summary.

## Removed in the 2026-08-17 cleanup
`CODEBASE-INVENTORY-AUDIT.md` (superseded by `CODEBASE-INVENTORY.md`),
`STAGING-DEPLOYMENT-REPORT.md`, `COOLIFY-STAGING-PREDEPLOY-CHECK.md`,
`POST-STAGING-PRODUCT-READINESS-REPORT.md` (defunct Coolify staging attempt),
`DEVOPS-UPDATE-2026-08-15.md` (dated DevOps snapshot).
