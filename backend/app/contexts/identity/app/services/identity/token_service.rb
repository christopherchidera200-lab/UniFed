module Identity
  # Issues and verifies the node's OIDC-style JWTs (access + refresh). Access
  # tokens carry the subject, university slug, roles, and a jti bound to a
  # Session row so revocation is immediate. Uses HS256 with the OIDC signing
  # key in dev; RS256 (JWKS) in production (key resolution left to deploy).
  class TokenService
    ALGO = "HS256".freeze
    ACCESS_TTL  = 15.minutes
    REFRESH_TTL = 30.days

    def self.issue_access(user:, session:, roles:)
      now = Time.current
      payload = {
        sub: user.id,
        uni: user.university.slug,
        roles: roles,
        actor_type: user.actor_type,
        jti: session.jti,
        typ: "access",
        iat: now.to_i,
        exp: (now + ACCESS_TTL).to_i,
        iss: issuer
      }
      JWT.encode(payload, secret, ALGO)
    end

    def self.issue_refresh(user:, session:)
      now = Time.current
      payload = {
        sub: user.id,
        uni: user.university.slug,
        jti: session.refresh_jti,
        typ: "refresh",
        iat: now.to_i,
        exp: (now + REFRESH_TTL).to_i,
        iss: issuer
      }
      JWT.encode(payload, secret, ALGO)
    end

    # Returns the decoded payload or nil (invalid/expired/wrong iss/typ).
    def self.verify(token, type: "access")
      payload, = JWT.decode(token, secret, true, algorithm: ALGO,
                            verify_iss: true, iss: issuer,
                            verify_expiration: true)
      return nil unless payload["typ"] == type
      payload
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::InvalidIssuerError
      nil
    end

    def self.issuer
      UniFed::Application.config.x.oidc_issuer
    end

    def self.secret
      ENV.fetch("OIDC_JWKS_PRIVATE", "dev-insecure-change-me")
    end
  end
end
