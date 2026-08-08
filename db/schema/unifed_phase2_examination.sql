-- UniFed Nigeria - Phase 2 depth: Examinations (scheduling)
CREATE TABLE exam_schedules (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id      UUID NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
    course_offering_id UUID NOT NULL REFERENCES course_offerings(id) ON DELETE CASCADE,
    exam_type          TEXT NOT NULL DEFAULT 'exam',
    starts_at          TIMESTAMPTZ NOT NULL,
    ends_at            TIMESTAMPTZ NOT NULL,
    venue              TEXT,
    invigilator        TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (exam_type IN ('ca','exam','resit')),
    CHECK (ends_at > starts_at)
);
CREATE INDEX idx_exam_schedule_uni_start ON exam_schedules(university_id, starts_at);
