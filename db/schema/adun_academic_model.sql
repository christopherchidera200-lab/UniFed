-- =============================================================================
-- UniFed Nigeria - ADUN Academic Data Model (PostgreSQL)
-- Milestone M1: Foundation + Vertical Slice 1 (Academic Records, Digital Student ID)
--
-- Authoring rules (ADR-0005):
--   * Hierarchy: University > Faculty > Department > Programme > Course > CourseOffering
--   * Calendar is DATA-DRIVEN (AcademicSession + Semester rows), never hardcoded.
--   * Faculty/Dept/Programme code schemes + matric pattern are CONFIG, not magic strings.
--   * No invented institutional data: only structure is enforced; values come from
--     Registry export later. Placeholders below are illustrative ONLY.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";     -- fuzzy search on names/titles

-- =============================================================================
-- 1. UNIVERSITY / INSTITUTION
-- =============================================================================
CREATE TABLE universities (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug                TEXT NOT NULL UNIQUE,                 -- 'adun'
    name                TEXT NOT NULL,                        -- 'Admiralty University of Nigeria'
    short_name          TEXT,                                 -- 'ADUN'
    kind                TEXT NOT NULL DEFAULT 'federal'
                        CHECK (kind IN ('federal','state','private','public')),
    owner               TEXT,                                 -- 'Nigerian Navy'
    country_iso         CHAR(2) NOT NULL DEFAULT 'NG',
    actor_uri           TEXT UNIQUE,                          -- https://adun.unifed.ng/ap/uni
    federation_enabled  BOOLEAN NOT NULL DEFAULT false,
    config_json         JSONB NOT NULL DEFAULT '{}'::jsonb,   -- matric pattern, code schemes
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- 2. FACULTY
-- =============================================================================
CREATE TABLE faculties (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id   UUID NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
    code            TEXT NOT NULL,                        -- 'FOS'
    name            TEXT NOT NULL,                        -- 'Faculty of Science'
    dean_name       TEXT,                                 -- WARNING: from Registry (placeholder)
    founding_year   INT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (university_id, code)
);
CREATE INDEX idx_faculties_uni ON faculties(university_id);

-- =============================================================================
-- 3. DEPARTMENT
-- =============================================================================
CREATE TABLE departments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id      UUID NOT NULL REFERENCES faculties(id) ON DELETE CASCADE,
    code            TEXT NOT NULL,                        -- 'CYB'
    name            TEXT NOT NULL,                        -- 'Cyber Security'
    hod_name        TEXT,                                 -- WARNING: from Registry
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (faculty_id, code)
);
CREATE INDEX idx_departments_faculty ON departments(faculty_id);

-- =============================================================================
-- 4. PROGRAMME (degree)
-- =============================================================================
CREATE TABLE programmes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id   UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    code            TEXT NOT NULL,                        -- 'CYB-BSC'
    name            TEXT NOT NULL,                        -- 'Cyber Security'
    degree_type     TEXT NOT NULL
                    CHECK (degree_type IN ('B.Sc','B.Eng','B.A','LL.B','M.Sc','Ph.D','PGD')),
    duration_years  INT NOT NULL CHECK (duration_years > 0 AND duration_years <= 10),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (department_id, code)
);
CREATE INDEX idx_programmes_dept ON programmes(department_id);

-- =============================================================================
-- 5. COURSE (catalogue entry, reusable across sessions)
-- =============================================================================
CREATE TABLE courses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    programme_id    UUID NOT NULL REFERENCES programmes(id) ON DELETE CASCADE,
    code            TEXT NOT NULL,                        -- 'CYB 302'
    title           TEXT NOT NULL,
    credit_units    INT NOT NULL CHECK (credit_units >= 0 AND credit_units <= 12),
    level           INT NOT NULL CHECK (level >= 100 AND level <= 800),
    semester        SMALLINT NOT NULL CHECK (semester IN (1,2)),
    prerequisites   UUID[] DEFAULT '{}',                  -- course ids; validated in app
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (programme_id, code)
);
CREATE INDEX idx_courses_programme ON courses(programme_id);
CREATE INDEX idx_courses_code_trgm ON courses USING gin (code gin_trgm_ops);

-- =============================================================================
-- 6. ACADEMIC SESSION (data-driven calendar root)
-- =============================================================================
CREATE TABLE academic_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id   UUID NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,                        -- '2025/2026'
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL CHECK (end_date > start_date),
    is_current      BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (university_id, name)
);
CREATE INDEX idx_sessions_uni ON academic_sessions(university_id);

-- =============================================================================
-- 7. SEMESTER (data-driven windows)
-- =============================================================================
CREATE TABLE semesters (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id          UUID NOT NULL REFERENCES academic_sessions(id) ON DELETE CASCADE,
    number              SMALLINT NOT NULL CHECK (number IN (1,2)),
    lecture_start       DATE NOT NULL,
    lecture_end         DATE NOT NULL CHECK (lecture_end >= lecture_start),
    exam_start          DATE NOT NULL,
    exam_end            DATE NOT NULL CHECK (exam_end >= exam_start),
    registration_open   DATE,
    registration_close  DATE,
    break_start         DATE,
    break_end           DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (session_id, number)
);
CREATE INDEX idx_semesters_session ON semesters(session_id);

-- =============================================================================
-- 8. LECTURER
-- =============================================================================
CREATE TABLE lecturers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id   UUID NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
    staff_id        TEXT,                                 -- WARNING: official scheme pending
    full_name       TEXT NOT NULL,
    department_id   UUID REFERENCES departments(id) ON DELETE SET NULL,
    title           TEXT,                                 -- 'Dr','Prof'
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_lecturers_uni ON lecturers(university_id);
CREATE INDEX idx_lecturers_dept ON lecturers(department_id);

-- =============================================================================
-- 9. STUDENT (academic record; PII boundary lives in Identity context)
-- =============================================================================
CREATE TABLE students (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id   UUID NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
    matric_no       TEXT NOT NULL,                        -- 'ADUN/FS/CYB/23/003'
    entry_year      INT NOT NULL,
    entry_mode      TEXT NOT NULL CHECK (entry_mode IN ('UTME','DE')),
    current_level   INT NOT NULL CHECK (current_level >= 100 AND current_level <= 800),
    status          TEXT NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','graduated','suspended','withdrawn','leave')),
    -- This links to the Identity context's OIDC account; FK enforced in app layer
    identity_subject TEXT UNIQUE,                         -- OIDC sub (nullable until linked)
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (university_id, matric_no)
);
CREATE INDEX idx_students_uni ON students(university_id);
CREATE INDEX idx_students_identity ON students(identity_subject);

-- Student <-> Programme enrollment (a student may switch; track history)
CREATE TABLE student_enrollments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id      UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    programme_id    UUID NOT NULL REFERENCES programmes(id) ON DELETE RESTRICT,
    session_id      UUID NOT NULL REFERENCES academic_sessions(id) ON DELETE RESTRICT,
    is_primary      BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, programme_id, session_id)
);
CREATE INDEX idx_enroll_student ON student_enrollments(student_id);

-- =============================================================================
-- 10. COURSE OFFERING (course x session x lecturer instance)
-- =============================================================================
CREATE TABLE course_offerings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id       UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    session_id      UUID NOT NULL REFERENCES academic_sessions(id) ON DELETE CASCADE,
    semester_number SMALLINT NOT NULL CHECK (semester_number IN (1,2)),
    lecturer_id     UUID REFERENCES lecturers(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (course_id, session_id, semester_number)
);
CREATE INDEX idx_offerings_session ON course_offerings(session_id);
CREATE INDEX idx_offerings_lecturer ON course_offerings(lecturer_id);

-- =============================================================================
-- 11. ACADEMIC RECORDS (Vertical Slice 1) - grades / results
-- =============================================================================
-- A grade entry: a student's result for one course offering.
CREATE TABLE grade_records (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id          UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    course_offering_id  UUID NOT NULL REFERENCES course_offerings(id) ON DELETE CASCADE,
    score               NUMERIC(5,2) CHECK (score >= 0 AND score <= 100),
    grade_letter        CHAR(2),                          -- A,B,C,D,E,F (NUC scale)
    grade_point         NUMERIC(3,2),                     -- 5.0 scale
    is_published        BOOLEAN NOT NULL DEFAULT false,   -- Registry release gate
    recorded_by         TEXT,                             -- staff_id / actor
    recorded_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, course_offering_id)
);
CREATE INDEX idx_grades_student ON grade_records(student_id);
CREATE INDEX idx_grades_offering ON grade_records(course_offering_id);

-- Transcript / CGPA rollup (materialized for performance; recomputed on grade publish)
CREATE TABLE academic_summaries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id      UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    session_id      UUID REFERENCES academic_sessions(id) ON DELETE SET NULL,
    total_credits   NUMERIC(6,2) NOT NULL DEFAULT 0,
    gpa             NUMERIC(4,2),                         -- per-session
    cgpa            NUMERIC(4,2),                         -- cumulative
    class_of_degree TEXT,                                -- First Class, 2:1, ...
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, session_id)
);
CREATE INDEX idx_summaries_student ON academic_summaries(student_id);

-- =============================================================================
-- 12. DIGITAL STUDENT ID (Vertical Slice 1)
-- =============================================================================
CREATE TABLE digital_student_ids (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id      UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    token_hash      TEXT NOT NULL UNIQUE,                 -- SHA-256 of the verifiable token
    qr_payload      JSONB NOT NULL,                       -- signed claims for offline scan
    status          TEXT NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','revoked','expired')),
    issued_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ NOT NULL,
    revoked_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_dsid_student ON digital_student_ids(student_id);

-- Verification audit log (privacy-by-design: who verified, when, result)
CREATE TABLE id_verification_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    digital_id_id   UUID NOT NULL REFERENCES digital_student_ids(id) ON DELETE CASCADE,
    verifier_actor  TEXT NOT NULL,                        -- URI or 'self'
    result          BOOLEAN NOT NULL,
    verified_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    ip_address      INET,
    user_agent      TEXT
);
CREATE INDEX idx_verify_log_id ON id_verification_logs(digital_id_id);

-- =============================================================================
-- 13. EVENT (ADUN gap-filler: the empty event calendar)
-- =============================================================================
CREATE TABLE events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id   UUID NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    type            TEXT NOT NULL
                    CHECK (type IN ('convocation','matriculation','siwes','exam','dept-event','general')),
    event_start     TIMESTAMPTZ NOT NULL,
    event_end       TIMESTAMPTZ,
    faculty_id      UUID REFERENCES faculties(id) ON DELETE SET NULL,
    department_id   UUID REFERENCES departments(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_events_uni ON events(university_id);
CREATE INDEX idx_events_type ON events(type);
CREATE INDEX idx_events_start ON events(event_start);

-- =============================================================================
-- 14. FEDERATION ACTOR REGISTRY (ADR-0003)
-- =============================================================================
CREATE TABLE federation_actors (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id   UUID NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
    actor_type      TEXT NOT NULL CHECK (actor_type IN ('university','user','group')),
    actor_uri       TEXT NOT NULL UNIQUE,                 -- globally unique AP actor id
    inbox_url       TEXT NOT NULL,
    outbox_url      TEXT NOT NULL,
    public_key_pem  TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_fed_actors_uni ON federation_actors(university_id);
