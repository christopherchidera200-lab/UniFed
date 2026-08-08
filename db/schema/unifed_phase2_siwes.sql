-- UniFed Nigeria - Phase 2: SIWES / Internship tracking
-- Placements (student <-> employer for a session) + weekly logs verified by
-- the workplace supervisor. Completion gate = REQUIRED_WEEKS verified logs.

CREATE TABLE siwes_placements (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id        UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    employer_profile_id UUID REFERENCES employer_profiles(id) ON DELETE SET NULL,
    academic_session_id UUID REFERENCES academic_sessions(id) ON DELETE SET NULL,
    employer_name     TEXT NOT NULL,
    supervisor_name   TEXT,
    supervisor_email  TEXT,
    start_date        DATE,
    end_date          DATE,
    status            TEXT NOT NULL DEFAULT 'pending',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, academic_session_id),
    CHECK (status IN ('pending','active','completed','terminated'))
);
CREATE INDEX idx_siwes_placement_student ON siwes_placements(student_id);

CREATE TABLE siwes_logs (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    siwes_placement_id UUID NOT NULL REFERENCES siwes_placements(id) ON DELETE CASCADE,
    week_number       INT NOT NULL CHECK (week_number >= 1 AND week_number <= 24),
    hours             NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (hours >= 0 AND hours <= 168),
    task_summary      TEXT,
    status            TEXT NOT NULL DEFAULT 'draft',
    verified_by       TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (siwes_placement_id, week_number),
    CHECK (status IN ('draft','submitted','verified'))
);
CREATE INDEX idx_siwes_log_placement ON siwes_logs(siwes_placement_id);
