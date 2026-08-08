module Career
  # An employer participating in the career hub. Universities may also post
  # opportunities (e.g. internships) via their own employer profile.
  class EmployerProfile < ::ApplicationRecord
    belongs_to :university, class_name: "Academic::University", optional: true
    has_many :career_opportunities, dependent: :destroy

    validates :name, presence: true
    validates :industry, inclusion: {
      in: %w[tech finance oil_gas public_sector health education other]
    }, allow_nil: true
  end
end
