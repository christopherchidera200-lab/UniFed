module Federation
  # Generates and wraps RSA keypairs for local actors. Private key is encrypted
  # at rest via the same envelope as MFA secrets (KMS-backed in production).
  class KeyService
    def self.generate_keypair
      key = OpenSSL::PKey::RSA.new(2048)
      { public_pem: key.public_key.to_pem, private_pem: key.to_pem }
    end

    def self.encrypt_private(pem)
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.encrypt
      key = OpenSSL::Digest::SHA256.digest(Identity::TokenService.secret)[0, 32]
      iv = cipher.random_iv
      cipher.key = key
      cipher.iv = iv
      cipher.auth_data = ""
      ct = cipher.update(pem) + cipher.final
      Base64.strict_encode64(iv + cipher.auth_tag + ct)
    end

    def self.decrypt_private(blob)
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
  end
end
