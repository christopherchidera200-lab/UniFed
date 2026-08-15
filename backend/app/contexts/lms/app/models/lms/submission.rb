module Lms
  # A student's submission to an Assignment. Graded by the lecturer; AI-generated
  # grades are advisory only — a lecturer must confirm/override (no silent AI grading).
  class Submission < ::ApplicationRecord
    self.table_name = "lms_submissions"

    belongs_to :assignment, class_name: "Lms::Assignment", inverse_of: :submissions
    belongs_to :student, class_name: "Academic::Student"

    validates :status, inclusion: { in: %w[draft submitted graded] }
    validates :student_id, uniqueness: { scope: :assignment_id, message: "already submitted" }

    def graded?
      status == "graded"
    end
  end
end
