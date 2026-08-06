module Academic
  class Course < ApplicationRecord
    belongs_to :programme
    has_many :course_offerings, dependent: :destroy

    validates :code, presence: true, uniqueness: { scope: :programme_id }
    validates :title, presence: true
    validates :credit_units, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 12 }
    validates :level, numericality: { greater_than_or_equal_to: 100, less_than_or_equal_to: 800 }
    validates :semester, inclusion: { in: [1, 2] }

    # prerequisites stored as course UUIDs (self-referential, validated in app).
    validate :prerequisites_exist

    private

    def prerequisites_exist
      return if prerequisites.blank?
      missing = prerequisites.reject { |id| Course.exists?(id) }
      errors.add(:prerequisites, "reference unknown course ids") if missing.any?
    end
  end
end
