# UniFed Nigeria — Data Retention Policy (DRAFT)

> **DRAFT — policy document. Retention periods are PROPOSED and REQUIRE LEGAL/INSTITUTIONAL
> APPROVAL (NDPA storage-limitation). No period is yet technically enforced unless noted.**

---

## 1. Principles
Data minimisation; purpose limitation; storage limitation; retain only as long as necessary.

## 2. Retention matrix

| DATA CATEGORY | PURPOSE | SOURCE | STORAGE | PROPOSED RETENTION | BASIS | DELETION METHOD | ANONYMIZATION | OWNER |
|---------------|---------|--------|---------|--------------------|--------|-----------------|----------------|--------|
| Identity / auth | Access control | User | PostgreSQL | Life of account + 90d | Contract/NDPA | Hard delete on closure | n/a | UniFed |
| Consent records | Lawful basis | User | PostgreSQL | **Indefinite (audit)** | NDPA art. | Append-only; mark withdrawn | n/a | UniFed |
| Profile | Service | User | PostgreSQL | Life of account | Consent | Delete on closure | n/a | UniFed |
| Academic records | Academic | University | PostgreSQL | **REQUIRES INSTITUTIONAL APPROVAL** | University policy | Per university retention | n/a | University |
| Student IDs | Identity proof | University | PostgreSQL | **REQUIRES INSTITUTIONAL APPROVAL** | University policy | Revoke on graduation/exit | n/a | University |
| Social posts | Communication | User | PostgreSQL | Life of account + 30d after delete | Consent | Soft delete → purge | Flag as deleted | User |
| Library loans | Service | User | PostgreSQL | **REQUIRES INSTITUTIONAL APPROVAL** | University policy | Per library policy | n/a | University |
| Career applications | Service | User | PostgreSQL | 24 months | Consent | Hard delete | n/a | UniFed |
| Notifications | Service | System | PostgreSQL/Redis | 90 days | Operational | Auto-expire | n/a | UniFed |
| Federation activities | Interop | Remote | PostgreSQL | 24 months | Federation policy | Purge | Tombstone | UniFed |
| Logs / audit | Security | System | (planned) | 12 months | Security/NDPA | Rotate | n/a | UniFed |
| Media (planned) | Service | User | Object storage | **REQUIRES LEGAL APPROVAL** | Consent | Delete on closure | n/a | UniFed |
| AI inference (planned) | Service | User | PostgreSQL | **REQUIRES LEGAL APPROVAL** | Consent | Delete on request | Anonymize | UniFed |

## 3. Enforcement status
**No automated purge jobs exist today.** Retention is DOCUMENTED POLICY only. Implementation of
scheduled deletion is required and is a tracked gap.

## 4. Review
Retention periods reviewed annually and on NDPA guidance changes. **LEGAL REVIEW REQUIRED.**
