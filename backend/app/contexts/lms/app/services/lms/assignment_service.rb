module Lms
  # Assignment / submission workflow service. Strict ownership: lecturers manage
  # assignments for offerings they teach; students submit only for their own
  # enrollments; grading is lecturer-only and may be overridden.
  class AssignmentService
    class << self
      def create!(lecturer:, course_offering:, attrs:)
        raise ArgumentError, "lecturer does not teach this offering" unless course_offering.lecturer_id == lecturer.id
        Assignment.new(attrs.merge(course_offering: course_offering, lecturer: lecturer)).tap(&:save!)
      end

      def publish!(assignment:)
        assignment.update!(published: true)
        assignment
      end

      def submit!(student:, assignment:, attrs:)
        raise ArgumentError, "assignment not published" unless assignment.published?
        Submission.create!(
          assignment: assignment, student: student,
          body: attrs[:body], attachment_ref: attrs[:attachment_ref],
          submitted_at: Time.current, status: "submitted"
        )
      end

      # Lecturer grades a submission. AI suggestions (future) are passed via
      # `ai_suggestion` but NEVER applied automatically.
      def grade!(submission:, lecturer:, score:, feedback: nil)
        assignment = submission.assignment
        raise ArgumentError, "not this lecturer's assignment" unless assignment.lecturer_id == lecturer.id
        submission.update!(score: score, feedback: feedback, status: "graded", graded_by_id: lecturer.id)
        submission
      end

      def for_course_offering(course_offering:)
        Assignment.where(course_offering_id: course_offering.id).order(created_at: :desc)
      end

      def for_student(student:)
        programme_ids = student.student_enrollments.pluck(:programme_id)
        session_ids = student.student_enrollments.pluck(:academic_session_id)
        course_ids = Academic::Course.where(programme_id: programme_ids).pluck(:id)
        offering_ids = Academic::CourseOffering
                         .where(course_id: course_ids, academic_session_id: session_ids)
                         .pluck(:id)
        Assignment.published.where(course_offering_id: offering_ids).order(due_at: :asc)
      end

      def submissions_for(assignment:, lecturer:)
        raise ArgumentError, "not this lecturer's assignment" unless assignment.lecturer_id == lecturer.id
        assignment.submissions.order(submitted_at: :asc)
      end
    end
  end
end
