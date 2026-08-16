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
        sub: user.id.to_s,
        uni: user.university.slug,
        roles: roles,
        actor_type: user.actor_type,
        jti: session.jti,
        typ: "access",
        aud: audience,
        iat: now.to_i,
        exp: (now + ACCESS_TTL).to_i,
        iss: issuer
      }
      JWT.encode(payload, secret, ALGO)
    end

    def self.issue_refresh(user:, session:)
      now = Time.current
      payload = {
        sub: user.id.to_s,
        uni: user.university.slug,
        jti: session.refresh_jti,
        typ: "refresh",
        aud: audience,
        iat: now.to_i,
        exp: (now + REFRESH_TTL).to_i,
        iss: issuer
      }
      JWT.encode(payload, secret, ALGO)
    end

    # Returns the decoded payload or nil (invalid/expired/wrong iss/typ/aud).
    def self.verify(token, type: "access")
      payload, = JWT.decode(token, secret, true, algorithm: ALGO,
                            verify_iss: true, iss: issuer,
                            verify_aud: true, aud: audience,
                            verify_expiration: true)
      return nil unless payload["typ"] == type
      payload
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::InvalidIssuerError, JWT::InvalidAudienceError
      nil
    end

    def self.issuer
      UniFed::Application.config.x.oidc_issuer
    end

    # F-02: the audience API tokens are bound to (distinct from the issuer).
    def self.audience
      UniFed::Application.config.x.oidc_audience
    end

    # Fail closed in PRODUCTION: tokens must be signed with a dedicated
    # TOKEN_SERVICE_SECRET that is DISTINCT from the RSA signing key
    # (OIDC_JWKS_PRIVATE). Reusing the RSA key would let the published RS256
    # public key double as the HMAC secret (JWT algorithm-confusion, vuln-0004).
    #
    # In non-production environments (dev/test/CI) we fall back to
    # OIDC_JWKS_PRIVATE so the suite and local dev keep working without a
    # second secret wired up — but production MUST set TOKEN_SERVICE_SECRET.
    KNOWN_BAD_SECRETS = %w[
      dev-insecure-change-me
      ci-insecure-not-for-prod
      change-me-in-prod
    ].freeze

    def self.secret
      secret = ENV["TOKEN_SERVICE_SECRET"].presence || fallback_secret
      if secret.blank? || KNOWN_BAD_SECRETS.include?(secret)
        raise "TOKEN_SERVICE_SECRET is not configured with a strong secret " \
              "(refusing to issue/verify tokens insecurely)"
      end
      secret
    end

    def self.fallback_secret
      # Dev/test only: tolerate the shared OIDC key so existing env templates and
      # CI keep booting. Production must supply TOKEN_SERVICE_SECRET instead.
      return ENV["OIDC_JWKS_PRIVATE"].to_s unless Rails.env.production?
      # In production without TOKEN_SERVICE_SECRET we refuse to fall back to the
      # RSA key — the caller must configure a dedicated secret.
      raise "TOKEN_SERVICE_SECRET must be set in production (distinct from OIDC_JWKS_PRIVATE)"
    end
  end
end
