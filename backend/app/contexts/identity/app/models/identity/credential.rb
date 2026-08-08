module Identity
  # Stored secret material. `password` kind holds an Argon2 hash in secret_enc.
  # Other kinds (totp/webauthn) store their encrypted material here so all
  # secret rotation flows through one table.
  class Credential < ApplicationRecord
    self.table_name = "identity_credentials"
    belongs_to :user, class_name: "Identity::User"

    validates :kind, inclusion: { in: %w[password totp webauthn] }
    validates :kind, uniqueness: { scope: :user_id }, if: -> { kind == "password" }

    # Verify a plaintext password against the Argon2 digest.
    def verify_password(plain)
      return false unless kind == "password" && secret_enc.present?
      Argon2::Password.verify_password(plain, secret_enc)
    rescue Argon2::Error
      false
    end

    # Build an Argon2 digest for storage.
    def self.hash_password(plain)
      Argon2::Password.create(plain, t_cost: 3, m_cost: 12)
    end
  end
end
