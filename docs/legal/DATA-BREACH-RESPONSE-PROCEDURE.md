# Data Breach Response Procedure (DRAFT)

> **DRAFT — REQUIRES REVIEW BY QUALIFIED NIGERIAN DATA PROTECTION / PRIVACY COUNSEL**
> Supports NDPA 2023 breach-notification obligations. Procedure only; not legal advice. The 72-hour
> figure is the NDPA statutory target and must be confirmed with counsel.

---

## 1. Objective

Detect, contain, assess, notify, and learn from personal-data breaches involving a UniFed instance.

## 2. Definitions

- **Personal data breach:** breach of security leading to accidental/unlawful destruction, loss,
  alteration, unauthorised disclosure of, or access to, personal data.

## 3. Roles

- UniFed security lead (technical containment).
- University DPO / controller (assessment + notification).
- UniFed DPO (coordination, cross-instance impact).

## 4. Detection & triage

- Sources: monitoring, the STRIX security findings, user reports, vendor notices.
- Classify severity (low/medium/high) by data sensitivity + scope.

## 5. Containment (immediate)

- Isolate affected systems; rotate secrets/tokens; revoke sessions; patch; preserve evidence.
- Apply STRIX remediation lessons (token-secret isolation, SSRF guards, signature verification).

## 6. Assessment (within [HOURS])

- What data, how many subjects, risk of harm. Determine if notifiable.

## 7. Notification

- Notify the University controller **without undue delay**.
- Where required, notify the Nigeria Data Protection Commission **within 72 hours** of awareness
  and affected data subjects where high risk — *confirm exact thresholds with counsel*.
- Coordinate cross-instance impact if federation was involved.

## 8. Remediation & reporting

- Fix root cause; document; update controls; post-incident review.

## 9. Record of breaches

- Maintain a breach register (date, nature, data, mitigation, notifications).

## 10. Federated breach

- If a breach originates at another instance, the receiving instance follows containment + notifies
  its University controller per `FEDERATION-POLICY-DRAFT.md`.
