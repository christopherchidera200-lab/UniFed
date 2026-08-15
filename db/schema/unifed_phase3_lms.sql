-- LMS / Assignments context (P0-2). Mirrors db/migrate/20260815000002_create_lms_context.rb.
CREATE TABLE IF NOT EXISTS lms_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_offering_id uuid NOT NULL,
  lecturer_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  instructions text,
  rubric jsonb DEFAULT '{}'::jsonb,
  max_score numeric(6,2) DEFAULT 100.0,
  due_at timestamp,
  published boolean DEFAULT false,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS index_lms_assignments_on_course_offering_id ON lms_assignments (course_offering_id);
CREATE INDEX IF NOT EXISTS index_lms_assignments_on_lecturer_id ON lms_assignments (lecturer_id);

CREATE TABLE IF NOT EXISTS lms_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id uuid NOT NULL,
  student_id uuid NOT NULL,
  body text,
  attachment_ref text,
  submitted_at timestamp,
  score numeric(6,2),
  feedback text,
  graded_by_id uuid,
  status text NOT NULL DEFAULT 'draft',
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS index_lms_submissions_on_assignment_id ON lms_submissions (assignment_id);
CREATE INDEX IF NOT EXISTS index_lms_submissions_on_student_id ON lms_submissions (student_id);
CREATE UNIQUE INDEX IF NOT EXISTS index_lms_submissions_uniq ON lms_submissions (assignment_id, student_id);

ALTER TABLE lms_assignments
  ADD CONSTRAINT fk_lms_assignments_offering FOREIGN KEY (course_offering_id) REFERENCES course_offerings (id);
ALTER TABLE lms_submissions
  ADD CONSTRAINT fk_lms_submissions_assignment FOREIGN KEY (assignment_id) REFERENCES lms_assignments (id);
