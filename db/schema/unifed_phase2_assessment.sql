-- UniFed Nigeria - Phase 2: Assessments
-- Component scores (CA/test/exam) per student per course offering.
-- Rolled into grade_records by AssessmentService; weights expressed in percent.

CREATE TABLE assessment_records (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id        UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    course_offering_id UUID NOT NULL REFERENCES course_offerings(id) ON DELETE CASCADE,
    component         TEXT NOT NULL,
    score             NUMERIC(5,2) NOT NULL CHECK (score >= 0 AND score <= 100),
    weight            NUMERIC(5,2) NOT NULL DEFAULT 100 CHECK (weight > 0 AND weight <= 100),
    recorded_by      TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, course_offering_id, component),
    CHECK (component IN ('ca1','ca2','test','exam','project','assignment'))
);
CREATE INDEX idx_assessment_student ON assessment_records(student_id);
CREATE INDEX idx_assessment_offering ON assessment_records(course_offering_id);
