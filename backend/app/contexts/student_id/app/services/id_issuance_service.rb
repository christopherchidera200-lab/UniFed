require "jwt"

module StudentId
  # Issues a signed digital student ID token (JWT) and stores only its hash.
  # The signed token is returned to the caller once; it is never persisted in
  # cleartext (privacy-by-design). QR payload carries the signed claims.
  class IdIssuanceService
    TTL = 1.year

    def self.issue!(student, issued_by:)
      new(student, issued_by: issued_by).call
    end

    def initialize(student, issued_by:)
      @student = student
      @issued_by = issued_by
    end

    def call
      token = build_token
      hash  = Digest::SHA256.hexdigest(token)

      id = StudentId::DigitalStudentId.create!(
        student: @student,
        token_hash: hash,
        qr_payload: claims,
        status: "active",
        issued_at: Time.current,
        expires_at: Time.current + TTL
      )
      # Return the one-time token to the issuer (display / QR render).
      { digital_id: id, token: token }
    end

    private

    def claims
      {
        sub: @student.id,
        matric: @student.matric_no,
        uni: @student.university.slug,
        level: @student.current_level,
        iat: Time.current.to_i,
        exp: (Time.current + TTL).to_i,
        iss: UniFed::Application.config.x.oidc_issuer
      }
    end

    def build_token
      JWT.encode(claims, secret, "HS256")
    end

    def secret
      # In production this is the OIDC signing key from Secrets Manager.
      ENV.fetch("OIDC_JWKS_PRIVATE", "dev-insecure-change-me")
    end
  end
end
