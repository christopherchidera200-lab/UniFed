module Research
  # A researcher's public profile, linked to an Identity user.
  class ResearchProfile < ::ApplicationRecord
    self.table_name = "research_profiles"
    belongs_to :user, class_name: "Identity::User"
    belongs_to :university, class_name: "Academic::University"
    has_many :publications, class_name: "Research::Publication", foreign_key: :profile_id, dependent: :nullify

    validates :user_id, uniqueness: true
    validates :orcid, format: { with: /\A\d{4}-\d{4}-\d{4}-\d{3}[\dX]\z/, allow_nil: true }
  end
end
