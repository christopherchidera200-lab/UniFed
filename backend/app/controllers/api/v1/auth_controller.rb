module Api
  module V1
    # Authentication endpoints (Phase 0). Issues JWTs via Identity::TokenService.
    class AuthController < BaseController
      skip_before_action :authenticate!, only: %i[login register refresh mfa_verify]

      # POST /api/v1/auth/register  {name, email, password, matric_no?}
      # -> {access_token, refresh_token} (auto-login) or {error, reason}
      def register
        result = Identity::RegistrationService.register(
          params: params.permit(:name, :display_name, :email, :password, :matric_no),
          ip: request.remote_ip,
          user_agent: request.user_agent
        )
        if result.success?
          render json: result.tokens.merge(expires_in: Identity::TokenService::ACCESS_TTL.to_i), status: result.status
        else
          render json: { error: result.reason }, status: result.status
        end
      end

      # POST /api/v1/auth/login  {email, password}
      # -> {access_token, refresh_token} OR {mfa_required, pre_auth_token}
      def login
        university = Academic::University.find_by(slug: params.dig(:uni_slug) || default_node)
        return render_unauthorized("unknown_node") unless university

        result = Identity::PasswordAuthService.authenticate(
          email: params.dig(:email),
          password: params.dig(:password),
          university: university,
          ip: request.remote_ip,
          user_agent: request.user_agent
        )
        return render_unauthorized(result.reason) unless result.ok?

        if result.mfa_required?
          render json: {
            mfa_required: true,
            pre_auth_token: build_pre_auth_jwt(result.pre_auth)
          }, status: :ok
        else
          render json: result.tokens, status: :ok
        end
      end

      # POST /api/v1/auth/mfa/verify  {pre_auth_token, code}
      # Completes step-up and returns tokens.
      def mfa_verify
        pre = decode_pre_auth(params.dig(:pre_auth_token))
        return render_unauthorized("invalid_pre_auth") unless pre
        user = Identity::User.find_by(id: pre[:user_id])
        return render_unauthorized("invalid_pre_auth") unless user

        unless Identity::MfaService.verify_totp(user, params.dig(:code))
          Identity::AuditService.log!(
            action: "auth.mfa_failed", actor_type: "user", actor_id: user.id,
            university_id: user.university_id, ip: request.remote_ip)
          return render_unauthorized("mfa_failed")
        end

        session = Identity::PasswordAuthService.create_session(user, request.remote_ip, request.user_agent)
        roles = user.roles.pluck(:name)
        render json: {
          access_token: Identity::TokenService.issue_access(user: user, session: session, roles: roles),
          refresh_token: Identity::TokenService.issue_refresh(user: user, session: session),
          expires_in: Identity::TokenService::ACCESS_TTL.to_i
        }, status: :ok
      end

      # POST /api/v1/auth/refresh  {refresh_token} -> new access token
      def refresh
        payload = Identity::TokenService.verify(params.dig(:refresh_token), type: "refresh")
        return render_unauthorized("invalid_refresh") unless payload
        session = Identity::Session.find_by(refresh_jti: payload["jti"])
        return render_unauthorized("revoked") if session.nil? || session.revoked?

        user = Identity::User.find_by(id: payload["sub"])
        return render_unauthorized("unknown_user") unless user

        new_access = Identity::TokenService.issue_access(
          user: user, session: session, roles: user.roles.pluck(:name))
        render json: { access_token: new_access, expires_in: Identity::TokenService::ACCESS_TTL.to_i }, status: :ok
      end

      # POST /api/v1/auth/logout  (requires auth) -> revoke current session
      def logout
        authenticate!
        session = Identity::Session.find_by(jti: jwt_payload["jti"])
        session&.revoke!
        Identity::AuditService.log!(
          action: "auth.logout", actor_type: "user", actor_id: current_subject,
          university_id: current_university&.id, ip: request.remote_ip)
        render json: { ok: true }, status: :ok
      end

      private

      def default_node
        UniFed::Application.config.x.node_slug
      end

      def build_pre_auth_jwt(pre)
        payload = { sub: pre.user_id, jti: pre.jti, typ: "pre_auth",
                    exp: pre.expires_at.to_i, iss: Identity::TokenService.issuer }
        JWT.encode(payload, Identity::TokenService.secret, Identity::TokenService::ALGO)
      end

      def decode_pre_auth(token)
        payload, = JWT.decode(token, Identity::TokenService.secret, true,
                              algorithm: Identity::TokenService::ALGO, verify_expiration: true)
        return nil unless payload["typ"] == "pre_auth"
        payload.symbolize_keys
      rescue JWT::DecodeError, JWT::ExpiredSignature
        nil
      end
    end
  end
end
