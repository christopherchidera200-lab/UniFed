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

    # In PRODUCTION the HS256 token secret MUST be a dedicated value that is
    # DISTINCT from the RS256 signing key (OIDC_JWKS_PRIVATE). The vuln-0004
    # risk was never merely "no dedicated secret exists" — it was "the HMAC
    # secret and the RSA private key are the SAME value", which lets the
    # published RS256 public key double as the HMAC secret. So we fail closed
    # if TOKEN_SERVICE_SECRET is unset OR equal to OIDC_JWKS_PRIVATE (or a
    # known-bad value).
    KNOWN_BAD_SECRETS = %w[
      dev-insecure-change-me
      ci-insecure-not-for-prod
      change-me-in-prod
    ].freeze

    def self.secret
      if Rails.env.production?
        secret = ENV["TOKEN_SERVICE_SECRET"].to_s
        rsa_key = ENV["OIDC_JWKS_PRIVATE"].to_s
        if secret.blank? || secret == rsa_key || KNOWN_BAD_SECRETS.include?(secret)
          raise "TOKEN_SERVICE_SECRET must be set in production, distinct from " \
                "OIDC_JWKS_PRIVATE, and not a known-bad value (JWT algorithm-" \
                "confusion risk, vuln-0004)"
        end
        return secret
      end

      # Non-production (dev/test/CI): use the dedicated secret when present;
      # otherwise fall back to the RSA key for local convenience. CI sets
      # TOKEN_SERVICE_SECRET explicitly, so CI exercises the real two-secret
      # path rather than this fallback.
      secret = ENV["TOKEN_SERVICE_SECRET"].presence || ENV["OIDC_JWKS_PRIVATE"].to_s
      if secret.blank? || KNOWN_BAD_SECRETS.include?(secret)
        raise "TOKEN_SERVICE_SECRET is not configured with a strong secret " \
              "(refusing to issue/verify tokens insecurely)"
      end
      secret
    end
  end
end
