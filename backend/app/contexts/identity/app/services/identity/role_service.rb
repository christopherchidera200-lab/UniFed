module Identity
  # RBAC helper: assign/revoke roles and resolve effective permissions for a
  # user. Permissions are dot-namespaced strings.
  class RoleService
    def self.assign(user:, role_name:, scope_type: "university", scope_id: nil)
      role = Identity::Role.find_by(name: role_name, university_id: user.university_id)
      return nil unless role
      Identity::RoleAssignment.find_or_create_by!(
        user: user, role: role, scope_type: scope_type, scope_id: scope_id
      )
      role
    end

    def self.revoke(user:, role_name:, scope_type: "university", scope_id: nil)
      role = Identity::Role.find_by(name: role_name, university_id: user.university_id)
      return false unless role
      Identity::RoleAssignment.where(
        user: user, role: role, scope_type: scope_type, scope_id: scope_id
      ).destroy_all.any?
    end

    def self.permissions_for(user)
      Identity::RoleAssignment.where(user: user)
        .joins(:role).pluck("identity_roles.permissions").flatten.uniq
    end

    # Ensure baseline roles exist for a university (idempotent).
    def self.seed_baseline_roles(university)
      baseline = {
        "student" => ["academic:read", "student_id:view", "profile:manage:self"],
        "staff"   => ["academic:read", "academic:write", "student_id:issue", "profile:manage:self"],
        "admin"   => ["admin:users", "admin:results", "admin:announcements", "admin:moderation",
                      "academic:read", "academic:write", "student_id:issue"]
      }
      baseline.each do |name, perms|
        Identity::Role.find_or_create_by!(name: name, university_id: university.id) do |r|
          r.permissions = perms
        end
      end
    end
  end
end
