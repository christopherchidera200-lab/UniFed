# Data Processing Register (DRAFT)

> **DRAFT — REQUIRES REVIEW BY QUALIFIED NIGERIAN DATA PROTECTION / PRIVACY COUNSEL**
> Maps processing activities to NDPA 2023 Art. obligations. Incomplete; requires University input.

---

## Processing activity register

| # | Activity | Purpose | Data categories | Subjects | Legal basis* | Recipients | Transfers | Retention | Security |
|---|---|---|---|---|---|---|---|---|---|
| PA-01 | Account authentication | Provide access | identity, auth | students/staff/admin | [CONFIRM] | University | none | account life | RBAC, MFA, hashing |
| PA-02 | Academic records | Education delivery | academic | students | [CONFIRM] | University | none | Univ policy | access control |
| PA-03 | Content/community | Platform features | content, comms | users | [CONFIRM] | University, federated instances | federation | until deletion | signing/SSRF guards |
| PA-04 | Career services | Employability | career, employer | students/employers | [CONFIRM] | University, employers | none | [PERIOD] | access control |
| PA-05 | Consent management | Lawful basis | consent ledger | users | consent | University | none | processing+[PERIOD] | ledger |
| PA-06 | Federation | Interop | actor metadata | federated users | [CONFIRM] | other instances | federation | defederation | signature verify |

`*` Legal basis column is **unconfirmed** — controller/processor roles and lawful basis must be
set with counsel and the University (see `DATA-PROTECTION-READINESS.md` §4).

## Sub-processors

| Sub-processor | Service | DPA status |
|---|---|---|
| [CLOUD HOSTING PROVIDER] | Infrastructure | **To be created** |
| [EMAIL/SMS PROVIDER] | Comms | **To be created** |

## Notes

- This register is a living document; update on each new feature (career, library, marketplace).
- Confirm whether a Record of Processing Activities (RoPA) filing is expected by NDPC.
