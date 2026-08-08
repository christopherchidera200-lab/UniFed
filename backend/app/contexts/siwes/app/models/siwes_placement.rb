module Siwes
  # A student's SIWES / internship placement at an employer for a session.
  class SiwesPlacement < ::ApplicationRecord
    belongs_to :student, class_name: "Academic::Student"
    belongs_to :employer_profile, class_name: "Career::EmployerProfile", optional: true
    belongs_to :academic_session, class_name: "Academic::AcademicSession", optional: true
    has_many :siwes_logs, dependent: :destroy

    validates :student_id, uniqueness: { scope: :academic_session_id }, allow_nil: true
    validates :status, inclusion: {
      in: %w[pending active completed terminated]
    }
    validate :end_after_start

    private

    def end_after_start
      return if end_date.blank? || start_date.blank?
      errors.add(:end_date, "must be after the start date") if end_date < start_date
    end
  end
end
