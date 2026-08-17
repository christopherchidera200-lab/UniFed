module Identity
  # A platform account. Links to an academic actor (Student / Lecturer) when
  # applicable. One account per (university, email). Role is derived from role
  # assignments (see RoleAssignment), but actor_type gives a fast primary kind.
  class User < ApplicationRecord
    self.table_name = "identity_users"
    belongs_to :university, class_name: "Academic::University"
    has_many :credentials, class_name: "Identity::Credential", dependent: :destroy
    has_many :mfa_devices, class_name: "Identity::MfaDevice", dependent: :destroy
    has_many :sessions, class_name: "Identity::Session", dependent: :destroy
    has_many :role_assignments, class_name: "Identity::RoleAssignment", dependent: :destroy
    has_many :roles, through: :role_assignments, class_name: "Identity::Role"
    has_many :consent_records, class_name: "Identity::ConsentRecord", dependent: :destroy

    validates :email, presence: true,
              uniqueness: { scope: :university_id, case_sensitive: false }
    validates :username, presence: true,
              uniqueness: { scope: :university_id }
    validates :actor_type, inclusion: { in: %w[student staff admin system] }

    enum :status, { active: "active", suspended: "suspended", deactivated: "deactivated" }, default: :active

    # Password credential convenience accessor.
    def password_credential
      credentials.find { |c| c.kind == "password" }
    end

    def mfa_enrolled?
      mfa_devices.where(confirmed: true).exists?
    end

    # Effective permission set across assigned roles.
    def permission_set
      roles.flat_map { |r| r.permissions }.uniq
    end

    def has_permission?(perm)
      permission_set.include?(perm)
    end

    def student?
      actor_type == "student" && actor_id.present?
    end

    def staff?
      actor_type == "staff" && actor_id.present?
    end

    def admin?
      actor_type == "admin"
    end
  end
end
