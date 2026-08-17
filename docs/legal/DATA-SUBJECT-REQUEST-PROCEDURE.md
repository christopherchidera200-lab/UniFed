# Data Subject Request (DSR) Procedure (DRAFT)

> **DRAFT — REQUIRES REVIEW BY QUALIFIED NIGERIAN DATA PROTECTION / PRIVACY COUNSEL**
> This procedure supports NDPA 2023 data-subject rights. It is a draft workflow, not legal advice.

---

## 1. Scope

Covers access, rectification, erasure, restriction, portability, objection, and consent withdrawal
for personal data in a UniFed instance.

## 2. Receiving a request

- Channel: [DSR EMAIL] / in-app request / university records office.
- Verify identity of the data subject before actioning (avoid unauthorised disclosure).

## 3. Triage & role

- If the University is controller: University owns the decision; UniFed provides tooling/export.
- Acknowledge within [ACK TIMEFRAME]; respond within NDPA statutory period ([CONFIRM, e.g., 30 days]).

## 4. Fulfilment paths (current technical status)

| Right | Technical support today | Action |
|---|---|---|
| Access | Partial (API reads) | Build export endpoint (MISSING) |
| Portability | MISSING | Implement data-export (MISSING) |
| Erasure | Partial (account `status` + cascade destroy) | Implement deletion/anonymisation workflow (MISSING) |
| Rectification | Via university admin | Standard admin ops |
| Withdraw consent | **Supported by `identity_consent_records`** (after Phase 4 fix) | Works post-fix |
| Restriction / objection | Manual | Document process |

## 5. Federation complication

Erasure/objection may not propagate to already-federated copies. Coordinate defederation or
targeted removal per `FEDERATION-POLICY-DRAFT.md`; certify effort.

## 6. Record keeping

Log each DSR (who, when, type, action, outcome) for accountability.

## 7. Escalation

If a request cannot be met, escalate to [UNIFED DPO] and the University controller; legal review
where refusal is considered.
