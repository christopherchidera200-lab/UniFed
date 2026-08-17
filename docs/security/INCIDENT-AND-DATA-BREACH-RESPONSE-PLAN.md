# UniFed Nigeria — Incident & Data Breach Response Plan (Security) (DRAFT)

> **DRAFT — security incident procedure (companion to the privacy breach plan). Owner roles marked
> OWNER TO BE APPOINTED. No live incident has occurred.**

---

## 1. Identification
Sources: monitoring/alerting (planned: CloudWatch/Prometheus), WAF, user reports, dependency
advisories, third-party notice.

## 2. Severity
SEV-1 Critical (active exploitation / mass PII) · SEV-2 High (targeted) · SEV-3 Medium (suspected).

## 3. Containment (technical)
- Rotate `OIDC_JWKS_PRIVATE`, `SECRET_KEY_BASE`, DB/Redis creds (fail-closed ensures boot rejects
  weak values).
- Revoke affected sessions/tokens (jti-bound sessions allow immediate revocation).
- Enable WAF rules / block IPs; throttle; disable vulnerable endpoint if needed.

## 4. Investigation & evidence
Preserve logs; export DB/Redis snapshots; reconstruct timeline. (Centralized logging is PLANNED —
currently partial.)

## 5. Notification
Per NDPA and contractual terms — **LEGAL REVIEW REQUIRED** for thresholds/timelines. Coordinate
with the privacy breach plan.

## 6. Recovery
Patch → re-test (incl. regression/security specs) → redeploy → monitor.

## 7. Post-incident
Blameless review; update controls and this plan.

## Owners
Incident Commander: **OWNER TO BE APPOINTED** · Security Lead: **OWNER TO BE APPOINTED** ·
Legal/Comms: **OWNER TO BE APPOINTED**.
