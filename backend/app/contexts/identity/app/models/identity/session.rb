module Identity
  # An authenticated session. The JWT access + refresh tokens reference the
  # jti/refresh_jti here so a logout/revoke invalidates them immediately.
  class Session < ApplicationRecord
    self.table_name = "identity_sessions"
    belongs_to :user, class_name: "Identity::User"

    validates :jti, :refresh_jti, presence: true, uniqueness: true

    scope :active, -> { where(revoked_at: nil).where("expired_at > ?", Time.current) }

    def revoked?
      revoked_at.present? || expired_at <= Time.current
    end

    def revoke!
      update!(revoked_at: Time.current)
    end
  end
end
