# ADR 0002: DynamoDB single-table design

## Status
Accepted

## Context
Access patterns are known and narrow. Relational joins are not needed. Cost predictability at
low volume matters more than query flexibility.

## Access patterns
| # | Pattern | Key |
|---|---------|-----|
| 1 | Get investigation by id | PK=`INV#<id>`, SK=`META` |
| 2 | List a user's investigations, newest first | GSI1PK=`USER#<sub>`, GSI1SK=`TS#<iso>` |
| 3 | Get all findings for an investigation | PK=`INV#<id>`, SK begins_with `FINDING#` |
| 4 | Cache a collector result by target | PK=`CACHE#<collector>#<target>`, SK=`RESULT` + TTL |
| 5 | Audit log per user per day | PK=`AUDIT#<sub>#<date>`, SK=`TS#<iso>` |

## Decision
Single table `cloudintel-main` with `PK`/`SK` and one GSI (`GSI1PK`/`GSI1SK`). On-demand billing.
TTL attribute `expires_at` drives retention and cache expiry for free.

## Consequences
- New access patterns may need a second GSI; acceptable.
- All item shapes live in `backend/app/storage/models.py` — the table is opaque elsewhere.
