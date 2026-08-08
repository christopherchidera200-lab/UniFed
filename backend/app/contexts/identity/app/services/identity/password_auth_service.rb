module Identity
  # First-factor authentication: verifies email + password, enforces status /
  # suspension, and either returns tokens (if no MFA enrolled or MFA already
  # satisfied) or a `mfa_required` challenge carrying a short-lived pre-auth
  # session token. Password failures are rate-limited by the controller layer.
  class PasswordAuthService
    PreAuth = Struct.new(:user_id, :jti, :expires_at)

    def self.authenticate(email:, password:, university:, ip:, user_agent:)
      user = Identity::User.find_by(email: email.to_s.downcase, university: university)
      return failure(:invalid_credentials) unless user
      return failure(:suspended) if user.suspended?

      cred = user.password_credential
      return failure(:invalid_credentials) unless cred && cred.verify_password(password)

      AuditService.log!(
        action: "auth.login", actor_type: "user", actor_id: user.id,
        university_id: user.university_id, ip: ip,
        meta: { result: "password_ok", user_agent: user_agent }
      )

      # No MFA enrolled → issue full session immediately.
      unless user.mfa_enrolled?
        return success(user, ip, user_agent)
      end

      # MFA enrolled → return a pre-auth challenge; tokens issued after MFA.
      pre = PreAuth.new(user.id, SecureRandom.hex(16), 5.minutes.from_now)
      AuditService.log!(
        action: "auth.mfa_required", actor_type: "user", actor_id: user.id,
        university_id: user.university_id, ip: ip,
        meta: { jti: pre.jti }
      )
      Result.new(ok: true, mfa_required: true, pre_auth: pre, user: user)
    end

    def self.success(user, ip, user_agent)
      session = create_session(user, ip, user_agent)
      roles = user.roles.pluck(:name)
      tokens = {
        access_token: TokenService.issue_access(user: user, session: session, roles: roles),
        refresh_token: TokenService.issue_refresh(user: user, session: session),
        expires_in: TokenService::ACCESS_TTL.to_i
      }
      Result.new(ok: true, mfa_required: false, tokens: tokens, user: user, session: session)
    end

    def self.create_session(user, ip, user_agent)
      Identity::Session.create!(
        user: user,
        jti: SecureRandom.hex(16),
        refresh_jti: SecureRandom.hex(16),
        ip: ip, user_agent: user_agent,
        expired_at: TokenService::REFRESH_TTL.from_now
      )
    end

    def self.failure(reason)
      Result.new(ok: false, reason: reason)
    end

    # Value object returned to controllers.
    class Result
      attr_reader :user, :session, :tokens, :pre_auth, :reason
      def initialize(ok:, mfa_required: false, tokens: nil, user: nil, session: nil, pre_auth: nil, reason: nil)
        @ok = ok; @mfa_required = mfa_required; @tokens = tokens
        @user = user; @session = session; @pre_auth = pre_auth; @reason = reason
      end
      def ok? = @ok
      def mfa_required? = @mfa_required
    end
  end
end
