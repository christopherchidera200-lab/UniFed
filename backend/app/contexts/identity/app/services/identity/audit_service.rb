module Identity
  # Thin writer over AuditLog. Centralises the audit write so every security /
  # compliance event flows through one place (NDPA / Zero-Trust audit trail).
  class AuditService
    def self.log!(action:, actor_type: nil, actor_id: nil, university_id: nil, ip: nil, meta: {})
      Identity::AuditLog.create!(
        action: action,
        actor_type: actor_type,
        actor_id: actor_id,
        university_id: university_id,
        ip: ip,
        meta: meta
      )
    rescue StandardError => e
      # Audit must never break the request path; surface in logs only.
      Rails.logger.error("audit_log_failed action=#{action} err=#{e.class}:#{e.message}")
    end
  end
end
