module Records
  # A grade entry for one student in one course offering.
  # NUC 5-point scale; letter bands are computed, not trusted from input.
  class GradeRecord < ApplicationRecord
    belongs_to :student, class_name: "Academic::Student"
    belongs_to :course_offering, class_name: "Academic::CourseOffering"

    validates :student_id, uniqueness: { scope: :course_offering_id }
    validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
              allow_nil: true

    # NUC grading bands (Nigeria). grade_point on a 5.0 scale.
    # Registry confirms exact bands/classification (⚠️ gap in brief).
    NUC_BANDS = [
      { letter: "A", min: 70, point: 5.0 },
      { letter: "B", min: 60, point: 4.0 },
      { letter: "C", min: 50, point: 3.0 },
      { letter: "D", min: 45, point: 2.0 },
      { letter: "E", min: 40, point: 1.0 },
      { letter: "F", min: 0,  point: 0.0 }
    ].freeze

    before_save :derive_grade, if: -> { score.present? && (score_changed? || grade_letter.nil?) }

    # Recompute letter + grade point from score.
    def derive_grade
      band = NUC_BANDS.find { |b| score >= b[:min] }
      self.grade_letter = band[:letter]
      self.grade_point  = band[:point]
    end

    def self.published_for(student)
      where(student: student, is_published: true)
    end
  end
end
