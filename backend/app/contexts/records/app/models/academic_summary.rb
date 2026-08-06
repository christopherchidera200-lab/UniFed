module Records
  # Per-session GPA and cumulative CGPA rollup (materialized).
  # Recomputed by AcademicSummaryService whenever a grade is published.
  class AcademicSummary < ApplicationRecord
    belongs_to :student, class_name: "Academic::Student"
    belongs_to :academic_session, class_name: "Academic::AcademicSession", optional: true

    validates :student_id, uniqueness: { scope: :academic_session_id }
    validates :gpa, :cgpa, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 },
              allow_nil: true
    validates :total_credits, numericality: { greater_than_or_equal_to: 0 }

    # NUC degree classification from final CGPA (⚠️ confirm bands with Registry).
    CLASS_OF_DEGREE = [
      { label: "First Class Honours",       min: 4.50 },
      { label: "Second Class Honours (Upper)", min: 3.50 },
      { label: "Second Class Honours (Lower)", min: 2.40 },
      { label: "Third Class Honours",       min: 1.50 },
      { label: "Pass",                      min: 1.00 }
    ].freeze

    def self.classify(cgpa)
      return nil if cgpa.nil?
      band = CLASS_OF_DEGREE.find { |b| cgpa >= b[:min] }
      band&.fetch(:label)
    end
  end
end
