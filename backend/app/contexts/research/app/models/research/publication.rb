module Research
  # A publication authored by a group or profile. DOI is advisory metadata;
  # no external API call is performed here (future integration is opt-in).
  class Publication < ::ApplicationRecord
    self.table_name = "research_publications"
    belongs_to :group, class_name: "Research::ResearchGroup", optional: true
    belongs_to :profile, class_name: "Research::ResearchProfile", optional: true
    belongs_to :university, class_name: "Academic::University"

    validates :title, presence: true
    validate :has_group_or_profile

    private

    def has_group_or_profile
      return if group_id.present? || profile_id.present?
      errors.add(:base, "publication must belong to a group or a profile")
    end
  end
end
