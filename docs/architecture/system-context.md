# UniFed System Context (C4 Level 1)

```
+---------------------------------------------------------------+
|                     UNIFED NIGERIA PLATFORM                   |
|                                                               |
|  +------------------+        +----------------------------+   |
|  |  Next.js Web     |        |   Flutter Mobile (later)   |   |
|  |  (design system)|        |                            |   |
|  +--------+---------+        +-------------+--------------+   |
|           |                                |                 |
|           v                                v                 |
|  +-------------------------------------------------------+   |
|  |              Rails API (modular monolith)             |   |
|  |  Identity | Academic | Records | StudentId | Fed      |   |
|  +----+-------------------------------------------+-----+   |
|       |                                           |         |
|       v                                           v         |
|  +----------+  +---------+  +-----------+  +-------------+  |
|  |PostgreSQL|  | Redis   |  | OpenSearch|  | S3 / MinIO  |  |
|  |(+PostGIS)|  |(sessions|  |(search)   |  | (media)     |  |
|  |          |  | +cache) |  |           |  |             |  |
|  +----------+  +---------+  +-----------+  +-------------+  |
|       |                                                           |
|       |  ActivityPub (JSON-LD, HTTP Signatures)                  |
|       +-------------------->  peer university nodes              |
|                                (unilag, unn, ui, ...)            |
+---------------------------------------------------------------+
```

## External integrations (ADUN)
- **ASIS** student portal (asis.adun.edu.ng) — onboarding / record source (⚠️ SSO spec pending)
- **SPGS** postgraduate portal (spgs.adun.edu.ng) — PG records (⚠️ not crawlable yet)
- **ICT Directorate** — auth/SSO authority (⚠️ IT policy gap)
- **JAMB / CAPS** — admissions pipeline (external, read-only reference)

## Non-goals for M1
- Blockchain consortium credential anchoring (deferred; federation axis covered in ADR-0003)
- Live streaming, marketplace, career hub, creator economy (later vertical slices)
- Flutter mobile (later phase; web-first)
