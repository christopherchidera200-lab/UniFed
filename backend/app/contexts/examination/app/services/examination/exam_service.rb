module Examination
  # Exam scheduling for a university. Lists upcoming sittings per course/
  # department and resolves seating/invigilation metadata. (M2 adds clash
  # detection across rooms + calendar export.)
  class ExamService
    def self.upcoming(university_id, course_offering_id: nil, limit: 50)
      scope = ExamSchedule.where(university_id: university_id).upcoming
      scope = scope.where(course_offering_id: course_offering_id) if course_offering_id.present?
      scope.limit(limit)
    end

    # Schedule a sitting; returns the persisted row.
    def self.schedule!(university:, course_offering:, exam_type:, starts_at:, ends_at:, venue: nil, invigilator: nil)
      ExamSchedule.create!(
        university: university, course_offering: course_offering, exam_type: exam_type,
        starts_at: starts_at, ends_at: ends_at, venue: venue, invigilator: invigilator
      )
    end
  end
end
