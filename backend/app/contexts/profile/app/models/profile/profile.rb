module Profile
  # Extended user profile for the Profile tab: bio, skills, portfolio, social
  # links, creator profile. One-to-one with Identity::User.
  class Profile < ApplicationRecord
    self.table_name = "profile_profiles"
    belongs_to :user, class_name: "Identity::User"

    validates :user_id, uniqueness: true
    validate :skills_are_array, :social_links_format

    def skills_are_array
      errors.add(:skills, "must be an array") unless skills.is_a?(Array)
    end

    def social_links_format
      return unless social_links.is_a?(Hash)
      unless social_links.values.all? { |v| v.is_a?(String) }
        errors.add(:social_links, "values must be strings")
      end
    end
  end
end
