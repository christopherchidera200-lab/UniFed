module Examination
  # A scheduled exam sitting for a course offering (venue, invigilator, seat).
  class ExamSchedule < ::ApplicationRecord
    belongs_to :university, class_name: "Academic::University"
    belongs_to :course_offering, class_name: "Academic::CourseOffering"

    validates :exam_type, inclusion: { in: %w[ca exam resit] }
    validates :starts_at, presence: true
    validate :ends_after_starts

    scope :upcoming, -> { where("starts_at >= ?", Time.current).order(starts_at: :asc) }

    private
    def ends_after_starts
      return if ends_at.blank? || starts_at.blank?
      errors.add(:ends_at, "must be after the start") if ends_at <= starts_at
    end
  end
end
