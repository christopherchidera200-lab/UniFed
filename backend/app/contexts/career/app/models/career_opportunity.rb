module Career
  # A job / internship / gig posted to the career hub.
  class CareerOpportunity < ::ApplicationRecord
    belongs_to :employer_profile
    has_many :career_applications, dependent: :destroy
    has_many :saved_jobs, dependent: :destroy

    validates :title, :employment_type, presence: true
    validates :employment_type, inclusion: {
      in: %w[full_time part_time internship contract gig apprenticeship]
    }
    validates :location_type, inclusion: { in: %w[remote hybrid on_site] }, allow_nil: true
    validates :status, inclusion: { in: %w[open closed draft expired] }

    scope :open, -> { where(status: "open") }
    scope :for_level, ->(level) { where("min_level IS NULL OR min_level <= ?", level) }
  end
end
