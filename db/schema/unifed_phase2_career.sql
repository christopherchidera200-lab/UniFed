-- UniFed Nigeria - Phase 2: Career Hub
-- Employer profiles, opportunities, applications, saved jobs.
-- Load order: after unifed_phase1_* (extends the ADUN academic model).

CREATE TABLE employer_profiles (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id UUID REFERENCES universities(id) ON DELETE SET NULL,
    name         TEXT NOT NULL,
    industry     TEXT,
    website      TEXT,
    description  TEXT,
    verified     BOOLEAN NOT NULL DEFAULT false,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_employer_uni ON employer_profiles(university_id);

CREATE TABLE career_opportunities (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employer_profile_id UUID NOT NULL REFERENCES employer_profiles(id) ON DELETE CASCADE,
    title             TEXT NOT NULL,
    description       TEXT,
    employment_type   TEXT NOT NULL,
    location_type     TEXT,
    location          TEXT,
    remote            BOOLEAN,
    salary_range      TEXT,
    min_level         INT,
    status            TEXT NOT NULL DEFAULT 'open',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (employment_type IN ('full_time','part_time','internship','contract','gig','apprenticeship')),
    CHECK (location_type IN ('remote','hybrid','on_site')),
    CHECK (status IN ('open','closed','draft','expired'))
);
CREATE INDEX idx_career_emp_type ON career_opportunities(employment_type);
CREATE INDEX idx_career_status ON career_opportunities(status);
CREATE INDEX idx_career_min_level ON career_opportunities(min_level);
CREATE INDEX idx_career_title_trgm ON career_opportunities USING gin (title gin_trgm_ops);

CREATE TABLE career_applications (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id           UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    career_opportunity_id UUID NOT NULL REFERENCES career_opportunities(id) ON DELETE CASCADE,
    employer_profile_id  UUID REFERENCES employer_profiles(id) ON DELETE SET NULL,
    cover_note           TEXT,
    status               TEXT NOT NULL DEFAULT 'submitted',
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, career_opportunity_id),
    CHECK (status IN ('submitted','under_review','shortlisted','interview','offer','rejected','withdrawn'))
);
CREATE INDEX idx_career_app_student ON career_applications(student_id);

CREATE TABLE saved_jobs (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id           UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    career_opportunity_id UUID NOT NULL REFERENCES career_opportunities(id) ON DELETE CASCADE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, career_opportunity_id)
);
CREATE INDEX idx_saved_jobs_student ON saved_jobs(student_id);
