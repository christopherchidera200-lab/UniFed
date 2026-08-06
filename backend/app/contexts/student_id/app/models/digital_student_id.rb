module StudentId
  # A verifiable digital student ID. The token is a signed JWT (offline
  # scannable via QR). Only the SHA-256 hash of the raw token is stored
  # (privacy-by-design: token never at rest in cleartext).
  class DigitalStudentId < ApplicationRecord
    belongs_to :student, class_name: "Academic::Student"
    has_many :verification_logs, dependent: :destroy

    validates :token_hash, presence: true, uniqueness: true
    validates :status, inclusion: { in: %w[active revoked expired] }
    validates :expires_at, presence: true
    validate :expires_after_issued

    before_validation :default_expiry, on: :create

    scope :active, -> { where(status: "active").where("expires_at > ?", Time.current) }

    def expired?
      expires_at <= Time.current
    end

    def revoke!(by:)
      update!(status: "revoked", revoked_at: Time.current)
      verification_logs.create!(verifier_actor: by.to_s, result: false)
    end

    private

    def default_expiry
      self.expires_at ||= 1.year.from_now
    end

    def expires_after_issued
      return unless issued_at && expires_at
      errors.add(:expires_at, "must be after issued_at") if expires_at <= issued_at
    end
  end
end
