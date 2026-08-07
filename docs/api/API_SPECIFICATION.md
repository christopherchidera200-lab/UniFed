# UniFed Nigeria — API Specification

> **M1 status:** `docs/api/openapi-slice1.yaml` is implemented (Academic Records + Digital Student ID).
> This document catalogues the **full target** API surface. ✅ = implemented in M1; 📋 = target.

## Conventions
- Base: `https://<instance>/api/v1`
- Auth: `Authorization: Bearer <jwt>`
- JSON; errors: `{ "error": "<message>", "details": [ ... ] }`
- Pagination: `?page=&per_page=` → `{ "data": [...], "meta": { "page", "per_page", "total" } }`

---

## 1. Identity & Academic (✅ built)
```
GET  /academic/students/:id/records        ✅  grade records for a student
GET  /academic/students/:id/summary         ✅  CGPA, totals, class of degree
POST /student-id/issue                       ✅  issue digital ID → { digital_id, token }
POST /student-id/verify                      ✅  verify token (logs success/failure)
GET  /student-id/:id                         ✅  digital ID record
```
Add: `GET /academic/courses`, `GET /academic/timetable`, `GET /academic/assignments`.

## 2. Auth & Security 📋
```
POST /auth/login (OIDC)            POST /auth/mfa/verify
POST /auth/refresh                 GET  /auth/sessions
POST /admin/roles                  GET  /admin/audit-logs
```

## 3. Social / Feed 📋
```
GET  /feed                         POST /posts            GET  /posts/:id
POST /stories                      POST /polls           POST /reactions
GET  /notifications                GET  /trending
```

## 4. Messaging 📋
```
GET  /conversations                POST /conversations
POST /conversations/:id/messages   GET  /conversations/:id/messages
POST /calls (initiate)             WS   /ws/messaging (presence/typing)
```

## 5. Collaboration 📋
```
POST /whiteboards                  POST /documents
POST /calendar/events              POST /study-rooms
```

## 6. Media / Live 📋
```
POST /streams (start)              GET  /streams/:id
POST /podcasts                     POST /recordings
WS   /streams/:id/live (chat/poll/q&a)
```

## 7. Search 📋
```
GET  /search?q=&type=             GET  /search/semantic
```

## 8. Career 📋
```
GET  /careers/internships          GET  /careers/jobs
POST /careers/cv                   POST /careers/interview-prep
```

## 9. Marketplace 📋
```
GET  /marketplace/listings         POST /marketplace/listings
POST /marketplace/orders
```

## 10. Research 📋
```
GET  /research/publications        POST /research/groups
POST /research/datasets
```

## 11. Wellbeing 📋
```
POST /wellbeing/checkin            POST /wellbeing/counselling
POST /wellbeing/emergency
```

## 12. Admin 📋
```
GET  /admin/students               GET  /admin/results
POST /admin/announcements          GET  /admin/moderation
```

## 13. Federation 📋 (ActivityPub)
```
GET  /.well-known/webfinger        POST /inbox   GET  /users/:actor/outbox
```
Standard ActivityPub vocabulary (Note, Video, Follow, Create).

## 14. Blockchain Trust 📋
```
POST /trust/anchor (credential hash)   GET  /trust/verify/:tx_hash
```

---

## M1 OpenAPI reference
The implemented subset is maintained at `docs/api/openapi-slice1.yaml` (Academic Records + Digital Student
ID). The full spec above is the target catalogue; each 📋 endpoint gets its own OpenAPI entry as built.
