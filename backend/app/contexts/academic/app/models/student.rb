module Academic
  # Student academic record. PII (name, DOB, contact) lives in the Identity
  # context; this table holds only academic identity (matric) + linkage.
  class Student < ::ApplicationRecord
    belongs_to :university
    has_many :student_enrollments, dependent: :destroy
    has_many :programmes, through: :student_enrollments
    has_many :grade_records, dependent: :destroy
    has_many :academic_summaries, class_name: "Records::AcademicSummary", dependent: :destroy
    has_many :digital_student_ids, class_name: "StudentId::DigitalStudentId", dependent: :destroy

    validates :matric_no, presence: true, uniqueness: { scope: :university_id }
    validates :entry_year, presence: true
    validates :entry_mode, inclusion: { in: %w[UTME DE] }
    validates :current_level, numericality: {
      greater_than_or_equal_to: 100, less_than_or_equal_to: 800
    }
    validates :status, inclusion: {
      in: %w[active graduated suspended withdrawn leave]
    }
    validates :identity_subject, uniqueness: true, allow_nil: true

    # Validate matric structurally against the university's configured pattern.
    validate :matric_matches_pattern, if: -> { university.present? }

    private

    def matric_matches_pattern
      return if university.valid_matric?(matric_no)
      errors.add(:matric_no, "does not match the university matric scheme")
    end
  end
end
