module Assessment
  # A component score (CA, test, exam, project) for a student in a course
  # offering. The AssessmentService rolls components into the final
  # grade_records score using each component's weight.
  class AssessmentRecord < ::ApplicationRecord
    belongs_to :student, class_name: "Academic::Student"
    belongs_to :course_offering, class_name: "Academic::CourseOffering"

    validates :student_id, uniqueness: { scope: %i[course_offering_id component] }
    validates :component, inclusion: { in: %w[ca1 ca2 test exam project assignment] }
    validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
    validates :weight, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

    before_validation :default_weight

    private

    def default_weight
      self.weight ||= 100 if component == "exam"
    end
  end
end
