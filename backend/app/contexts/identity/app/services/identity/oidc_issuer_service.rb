module Identity
  # OIDC token issuer. Builds access + ID tokens (RS256) and resolves userinfo.
  # Reuses PasswordAuthService for credential checks and TokenService for JWTs.
  class OidcIssuerService
    ISSUER = -> { UniFed::Application.config.x.oidc_issuer }
    TTL_ACCESS = 900  # 15 minutes
    TTL_REFRESH = 86_400 * 30

    # Resource Owner Password Credentials grant (used by the SPA / first-party).
    def self.password_grant(username:, password:, audience: nil)
      user = Identity::User.find_by(email: username.to_s.downcase) ||
             Identity::User.find_by(username: username.to_s.downcase)
      return { error: :invalid_credentials } unless user
      result = Identity::PasswordAuthService.authenticate(
        email: user.email,
        password: password,
        university: user.university,
        ip: "oidc",
        user_agent: "oidc"
      )
      return { error: result.reason } unless result.ok?

      if result.mfa_required?
        return { error: :mfa_required, mfa_token: result.mfa_token,
                 methods: result.available_methods }
      end
      issue_for(user, audience)
    end

    # Refresh grant.
    def self.refresh_grant(refresh_token:, audience: nil)
      payload = decode(refresh_token)
      return { error: :invalid_grant } unless payload && payload[:typ] == "refresh"
      user = Identity::User.find_by(id: payload[:sub])
      return { error: :invalid_grant } unless user
      issue_for(user, audience)
    rescue JWT::DecodeError
      { error: :invalid_grant }
    end

    # Build tokens for a user.
    def self.issue_for(user, audience = nil)
      now = Time.now.to_i
      base = {
        iss: ISSUER.call,
        sub: user.id,
        aud: audience || ISSUER.call,
        iat: now,
        azp: audience
      }
      access = sign(base.merge(
        typ: "access",
        exp: now + TTL_ACCESS,
        scope: "openid profile academic:read",
        email: user.email,
        name: user.display_name
      ))
      id_token = sign(base.merge(
        typ: "id_token",
        exp: now + TTL_ACCESS,
        nonce: nil,
        email: user.email,
        name: user.display_name,
        preferred_username: user.username
      ))
      refresh = sign(base.merge(typ: "refresh", exp: now + TTL_REFRESH))
      {
        access_token: access,
        id_token: id_token,
        refresh_token: refresh,
        token_type: "Bearer",
        expires_in: TTL_ACCESS,
        scope: "openid profile academic:read"
      }
    end

    # Claims for the OIDC userinfo endpoint.
    def self.userinfo(access_token)
      payload = decode(access_token)
      return nil unless payload && payload[:typ] == "access"
      user = Identity::User.find_by(id: payload[:sub])
      return nil unless user
      {
        sub: user.id,
        email: user.email,
        email_verified: true,
        name: user.display_name,
        preferred_username: user.username,
        actor_type: user.actor_type
      }
    rescue JWT::DecodeError
      nil
    end

    # Discovery document claims supported.
    def self.discovery
      issuer = ISSUER.call
      {
        issuer: issuer,
        authorization_endpoint: "#{issuer}/oauth/authorize",
        token_endpoint: "#{issuer}/oauth/token",
        userinfo_endpoint: "#{issuer}/oauth/userinfo",
        jwks_uri: "#{issuer}/.well-known/jwks.json",
        response_types_supported: %w[code token id_token],
        subject_types_supported: %w[public pairwise],
        id_token_signing_alg_values_supported: %w[RS256],
        scopes_supported: %w[openid profile academic:read],
        claims_supported: %w[sub email name preferred_username actor_type],
        token_endpoint_auth_methods_supported: %w[client_secret_post none]
      }
    end

    def self.decode(token)
      JWT.decode(token, OidcKeyService.public_key, true, algorithm: "RS256").first&.with_indifferent_access
    rescue JWT::DecodeError
      nil
    end

    def self.sign(payload)
      JWT.encode(payload, OidcKeyService.private_key, "RS256", kid: OidcKeyService::KID)
    end
  end
end
