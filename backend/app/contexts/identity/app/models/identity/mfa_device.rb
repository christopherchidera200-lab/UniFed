module Identity
  # A registered MFA factor. TOTP stores the (encrypted) base32 secret; WebAuthn
  # stores the credential public key + credential_id.
  class MfaDevice < ApplicationRecord
    self.table_name = "identity_mfa_devices"
    belongs_to :user, class_name: "Identity::User"

    validates :kind, inclusion: { in: %w[totp webauthn] }
    validates :label, presence: true

    scope :confirmed, -> { where(confirmed: true) }

    def totp?  = kind == "totp"
    def webauthn? = kind == "webauthn"
  end
end
