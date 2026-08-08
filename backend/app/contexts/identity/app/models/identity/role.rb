module Identity
  # A named RBAC role with a permissions array. Permission strings are
  # dot-namespaced, e.g. "academic:read", "student_id:issue", "admin:users".
  class Role < ApplicationRecord
    self.table_name = "identity_roles"
    has_many :role_assignments, class_name: "Identity::RoleAssignment", dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :university_id }
    validates :university_id, presence: true

    # `permissions` stored as JSON array of strings.
    def permission_list
      (permissions || []).map(&:to_s)
    end
  end
end
