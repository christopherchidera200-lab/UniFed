module Research
  # Membership of a user in a research group (role: lead | member).
  class GroupMembership < ::ApplicationRecord
    self.table_name = "research_group_memberships"
    belongs_to :group, class_name: "Research::ResearchGroup"
    belongs_to :user, class_name: "Identity::User"

    validates :role, inclusion: { in: %w[lead member] }
    validates :user_id, uniqueness: { scope: :group_id }
  end
end
