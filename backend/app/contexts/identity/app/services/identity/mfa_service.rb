module Identity
  # MFA enrollment + verification. Supports TOTP (RFC 6238) and WebAuthn
  # (FIDO2) factors. TOTP secret is encrypted at rest; WebAuthn public key is
  # stored as the credential material.
  class MfaService
    # Begin TOTP enrollment: generate a secret, return provisioning URI. The
    # device stays unconfirmed until the first code is verified.
    def self.begin_totp(user, label: "Authenticator")
      secret = ROTP::Base32.random_base32
      enc = encrypt(secret)
      device = Identity::MfaDevice.create!(
        user: user, kind: "totp", label: label,
        secret_enc: enc, confirmed: false
      )
      uri = totp(secret).provisioning_uri("#{user.email}:#{user.university.slug}")
      { device_id: device.id, otpauth_uri: uri, secret: secret }
    end

    # Confirm a TOTP device by checking the supplied code.
    def self.confirm_totp(user, device_id, code)
      device = user.mfa_devices.find(device_id)
      return false unless device&.totp? && !device.confirmed
      secret = decrypt(device.secret_enc)
      ok = totp(secret).verify(code.to_s, drift_behind: 15, drift_ahead: 15)
      device.update!(confirmed: true) if ok
      ok ? true : false
    end

    # Verify a TOTP code during step-up / login.
    def self.verify_totp(user, code)
      user.mfa_devices.where(kind: "totp", confirmed: true).any? do |d|
        secret = decrypt(d.secret_enc)
        totp(secret).verify(code.to_s, drift_behind: 15, drift_ahead: 15)
      end
    end

    # WebAuthn registration (returns the challenge to be signed by the client).
    def self.begin_webauthn(user)
      options = WebAuthn::Credential.options_for_create(user_present: true)
      # Persist the challenge temporarily on the user for the next call.
      user.update!(webauthn_challenge: options.challenge)
      options
    end

    def self.finish_webauthn(user, label:, credential:, client_data_json:, attestation_object:)
      return false unless user.webauthn_challenge.present?
      begin
        cred = WebAuthn::Credential.from_create(
          credential: credential,
          client_data_json: client_data_json,
          attestation_object: attestation_object,
          challenge: user.webauthn_challenge
        )
        Identity::MfaDevice.create!(
          user: user, kind: "webauthn", label: label,
          credential_id: cred.id, public_key: cred.public_key, confirmed: true
        )
        user.update!(webauthn_challenge: nil)
        true
      rescue WebAuthn::Error
        false
      end
    end

    def self.verify_webauthn(user, credential:, client_data_json:, authenticator_data:, signature:)
      device = user.mfa_devices.find { |d| d.webauthn? && d.credential_id == credential }
      return false unless device&.confirmed
      begin
        WebAuthn::Credential.from_get(
          credential: { id: device.credential_id, public_key: device.public_key,
                        sign_count: 0 },
          client_data_json: client_data_json,
          authenticator_data: authenticator_data,
          signature: signature,
          challenge: user.webauthn_challenge || ""
        )
        true
      rescue WebAuthn::Error
        false
      end
    end

    def self.encrypt(plain)
      # Lightweight envelope: AES-GCM with a key derived from the OIDC secret.
      # In production this is backed by KMS; keep the interface identical.
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.encrypt
      key = OpenSSL::Digest::SHA256.digest(Identity::TokenService.secret)[0, 32]
      iv = cipher.random_iv
      cipher.key = key
      cipher.iv = iv
      cipher.auth_data = ""
      ct = cipher.update(plain) + cipher.final
      tag = cipher.auth_tag
      Base64.strict_encode64(iv + tag + ct)
    end

    def self.decrypt(blob)
      raw = Base64.strict_decode64(blob)
      iv, tag, ct = raw[0, 12], raw[12, 16], raw[28..]
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.decrypt
      key = OpenSSL::Digest::SHA256.digest(Identity::TokenService.secret)[0, 32]
      cipher.key = key
      cipher.iv = iv
      cipher.auth_tag = tag
      cipher.auth_data = ""
      cipher.update(ct) + cipher.final
    end

    def self.totp(secret)
      ROTP::TOTP.new(secret, issuer: "UniFed")
    end
  end
end
