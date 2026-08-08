module Identity
  # Append-only audit trail for security- and compliance-relevant actions
  # (logins, MFA, credential/identity ops, admin actions). Never updated/deleted
  # in normal operation (NDPA / Zero-Trust audit requirement).
  class AuditLog < ApplicationRecord
    self.table_name = "identity_audit_logs"
    belongs_to :university, class_name: "Academic::University", optional: true

    validates :action, presence: true
    validates :actor_type, inclusion: { in: %w[user system admin] }, allow_nil: true

    # Convenience constructor used by AuditService.
    def self.record!(**attrs)
      create!(**attrs)
    end
  end
end
