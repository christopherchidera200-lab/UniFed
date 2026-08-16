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
        sub: user.id,
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

    # Fail closed: never fall back to an insecure, guessable, or empty secret.
    # A forgeable default previously allowed anyone who knew the value to mint
    # valid admin tokens (auth bypass / privilege escalation). The deployment
    # MUST inject a strong, random OIDC_JWKS_PRIVATE; we refuse to boot insecurely.
    KNOWN_BAD_SECRETS = %w[
      dev-insecure-change-me
      ci-insecure-not-for-prod
      change-me-in-prod
    ].freeze

    def self.secret
      secret = ENV["OIDC_JWKS_PRIVATE"].to_s
      if secret.empty? || KNOWN_BAD_SECRETS.include?(secret)
        raise "OIDC_JWKS_PRIVATE is not configured with a strong secret " \
              "(refusing to issue/verify tokens insecurely)"
      end
      secret
    end
  end
end
