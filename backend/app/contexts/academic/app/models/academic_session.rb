module Academic
  # Data-driven academic calendar root (ADR-0005). Never hardcode dates.
  class AcademicSession < ::ApplicationRecord
    belongs_to :university
    has_many :semesters, dependent: :destroy
    has_many :course_offerings, through: :semesters
    has_many :student_enrollments, dependent: :restrict_with_error

    validates :name, presence: true, uniqueness: { scope: :university_id }
    validates :start_date, presence: true
    validates :end_date, presence: true
    validate  :end_after_start

    # Enforce a single current session per university.
    after_save :ensure_single_current, if: :saved_change_to_is_current?

    scope :current, -> { where(is_current: true) }

    private

    def end_after_start
      return unless start_date && end_date
      errors.add(:end_date, "must be after start_date") if end_date <= start_date
    end

    def ensure_single_current
      return unless is_current
      university.academic_sessions.where(is_current: true).where.not(id: id).update_all(is_current: false)
    end
  end
end
