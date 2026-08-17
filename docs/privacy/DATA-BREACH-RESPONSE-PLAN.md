# UniFed Nigeria — Data Breach Response Plan (DRAFT)

> **DRAFT — plan. Owners marked OWNER TO BE APPOINTED where not yet designated. No incident has
> occurred; this is a prepared procedure, not evidence of a breach.**

---

## 1. Incident identification
- Triggers: IDS/monitoring alert, third-party notice, user report, failed security control.
- First responder: on-call engineer → notifies Incident Owner.

## 2. Severity classification
| Level | Criteria | Owner |
|-------|----------|-------|
| SEV-1 (Critical) | Confirmed exposure of credentials/PII at scale | **OWNER TO BE APPOINTED** |
| SEV-2 (High) | Targeted breach, limited PII | **OWNER TO BE APPOINTED** |
| SEV-3 (Medium) | Suspected, contained | **OWNER TO BE APPOINTED** |

## 3. Containment
Isolate affected service; rotate secrets (OIDC_JWKS_PRIVATE, SECRET_KEY_BASE, DB/Redis creds);
disable compromised tokens/sessions; block attacker IPs.

## 4. Investigation
Preserve logs (centralized logging planned); timeline reconstruction; root-cause analysis.

## 5. Evidence preservation
Snapshot DB/Redis; export relevant logs; maintain chain of custody.

## 6. Notification decision
**LEGAL REVIEW REQUIRED** — NDPC and data-subject notification thresholds/timelines per NDPA.
Do not assert specific deadlines without counsel.

## 7. Affected-user communication
Template prepared; send via email/notification; avoid disclosing investigative detail.

## 8. Regulator escalation
Per NDPA (LEGAL REVIEW REQUIRED). Owner: **OWNER TO BE APPOINTED**.

## 9. Recovery
Patch root cause; re-deploy; verify controls (re-run STRIX-style validation); monitor.

## 10. Post-incident review
Blameless retrospective; update this plan; track action items.

## 11. Documentation
All steps logged in incident record. Exercise (tabletop) recommended pre-pilot.

**Owners: OWNER TO BE APPOINTED for Incident Owner, Comms, Legal/Regulatory.**
