# UniFed Nigeria — Target Database Schema

> **M1 status:** `db/schema/adun_academic_model.sql` is implemented and loaded (17 tables: universities →
> grade_records, digital_student_ids, id_verification_logs). It is the source of truth for the Academic/
> Records/StudentId domains.
> **This file** describes the **target** schema for the full platform. Tables already implemented are marked
> ✅; others are 📋 (design). Schema is PostgreSQL 16, UUID PKs (`gen_random_uuid()`), `pgcrypto` + `pg_trgm`.

## Conventions
- PK `id uuid default gen_random_uuid() primary key`.
- `created_at`/`updated_at` timestamps on every table.
- Soft-delete via `deleted_at` where user-visible.
- Tenant = `university_id` on most domain tables (data ownership per instance).
- No social content on-chain; chain only stores credential/audit anchors (see BlockchainTrust).

---

## 1. Identity & Institution ✅ (built)
```
universities ✅        faculties ✅        departments ✅
programmes ✅          students ✅         staff ✅
digital_student_ids ✅ id_verification_logs ✅
```
M1 SQL at `db/schema/adun_academic_model.sql`. Add later: `roles`, `user_sessions`, `mfa_devices`,
`oauth_clients`, `consent_records` (NDPA).

## 2. Academic & Records ✅ (built)
```
courses ✅             course_offerings ✅
grade_records ✅      academic_summaries ✅
```
Extend with: `assignments`, `assignment_submissions`, `grading_rubrics`, `assignment_feedbacks`,
`attendances`, `timetables`, `semester_enrollments`.

## 3. Social / Feed 📋
```
users (actor_uri unique)         posts           stories
short_videos                     polls            poll_votes
comments                         reactions         followers
notifications                    trending_scores   feeds (materialised)
```
Federation columns: `actor_uri`, `remote_instance`, `federated_at`.

## 4. Messaging 📋
```
conversations  conversation_members  messages
message_status (read/receipt)  calls (WebRTC/SFU)  call_participants
```

## 5. Collaboration 📋
```
whiteboards  documents  document_blocks  calendars
calendar_events  study_rooms  meeting_recordings  pomodoro_sessions
```

## 6. Media / Live 📋
```
streams  stream_views  podcasts  podcast_episodes
recordings  captions  reactions_live  qa_sessions  live_polls
```

## 7. Search 📋
```
search_index (OpenSearch, not PG)   embeddings (pgvector)   semantic_queries
```

## 8. Career 📋
```
internships  jobs  employers  alumni_mentorships
cvs  interview_prep_sessions  career_fairs  skill_assessments
```

## 9. Marketplace 📋
```
listings  orders  order_items  (future payments table)
```

## 10. Research 📋
```
research_groups  publications  datasets  grants
citations  doi_records  lab_collaborations
```

## 11. Creator 📋
```
creator_profiles  creator_analytics  monetizations (future)
```

## 12. Wellbeing 📋
```
counselling_appointments  medical_appointments  wellbeing_checkins  emergency_contacts
```

## 13. Admin 📋
```
admin_roles  admin_role_assignments  moderation_flags  audit_logs  announcements
(university/faculty/dept/student-union/official)
```

## 14. Blockchain Trust 📋 (off-chain mirror; on-chain anchors)
```
credential_anchors (hash, tx_hash, anchored_at)
diplomas  transcript_verifications  credit_transfers  governance_records  chain_audit_trails
```
On-chain: permissioned Hyperledger Fabric / Polygon PoS (consortium). PG stores the mirror + tx receipt.

## 15. AI 📋
```
ai_requests  ai_summaries  ai_grades  ai_recommendations  ai_moderation_flags  model_routing
```

---

## Indexing strategy
- Unique-scoped indexes: `grade_records(course_offering_id, student_id)`, `digital_student_ids(student_id)`,
  `course_offerings(course_id, academic_session_id, semester_number)`.
- `pg_trgm` GIN indexes on `name`/`title` for fuzzy search.
- Partition `messages`/`posts` by `university_id` + time at scale.

## Migration path
M1 SQL is authoritative for the 3 built domains. New domains get their own migration files +
`db/schema/<domain>_model.sql` (kept in sync with the migration, as M1 established). `rails db:migrate`
becomes the deploy step once Ruby 4.0 tooling is replaced/upgraded in CI.
