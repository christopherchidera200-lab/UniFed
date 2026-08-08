module Identity
  # Binds a User to a Role within a scope (university-wide or a department).
  class RoleAssignment < ApplicationRecord
    self.table_name = "identity_role_assignments"
    belongs_to :user, class_name: "Identity::User"
    belongs_to :role, class_name: "Identity::Role"

    validates :scope_type, inclusion: { in: %w[university department programme] }
    validates :role_id, uniqueness: { scope: %i[user_id scope_type scope_id] }

    def self.for_user(user)
      where(user_id: user.id)
    end
  end
end
