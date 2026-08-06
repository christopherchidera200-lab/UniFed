# ADR-0005: ADUN Academic Data Model (authoritative for M1)

- **Status:** Accepted (data-model skeleton; ⚠️ fields pending Registry confirmation)
- **Date:** 2026-08-06

## Source

ADUN Research Brief (Aug 2026): 5 faculties, 26–29 programmes, ~208 faculty, ~6,200 students.
Main campus Ibusa (Delta State) + Asaba + Sapele satellite campuses.

## Hierarchy

```
University
 └─ Faculty (5): Science(FOS), Law(FOL), Engineering/FEET, Maritime(FMS),
                  Accounting/Mgmt/Social Sciences(FAMSS)
    └─ Department (e.g. Computer Science, Cyber Security, Software Engineering …)
       └─ Programme (degree: B.Sc / B.Eng / B.A / LL.B)
          └─ Course (code "CYB 302", credits, level, semester)
             └─ CourseOffering (course × session × lecturer)

AcademicSession ("2025/2026")
 └─ Semester (1/2): lecture windows, exam windows, registration & break windows (data-driven,
    NOT hardcoded — brief notes "calendar is subject to change" each session)

Student  (matric e.g. "ADUN/FS/CYB/23/003" — PATTERN ⚠️ UNCONFIRMED, drive validation off config)
Lecturer
Event    (convocation, matriculation, SIWES, exam, dept-event)
```

## Principles

1. **Data-driven calendar:** `AcademicSession` + `Semester` rows, not constants.
2. **Configurable codes:** faculty/department/programme code schemes and the matric pattern are
   **configuration**, not magic strings — pending Registry confirmation of the real scheme.
3. **No invented institutional data:** names/colours/logos wait for official ADUN assets. The
   structure (5 faculties, deans listed in brief) is modeled; specific course catalogues, fee
   schedules, grading bands, and staff directories are ⚠️ gaps filled later via Registry export.
4. **Privacy-by-design:** student PII is in the `Identity`/`Academic` boundary; grades/records are
   access-controlled by role + the owning university.

## See

Executable schema: `db/schema/adun_academic_model.sql` (PostgreSQL).
