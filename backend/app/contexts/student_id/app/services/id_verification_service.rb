require "jwt"

module StudentId
  # Verifies a presented digital student ID token (offline-friendly scan).
  # Returns the linked student if valid, active, and unexpired; logs every attempt.
  class IdVerificationService
    def self.verify!(token, verifier_actor:, ip: nil, user_agent: nil)
      new(token, verifier_actor: verifier_actor, ip: ip, user_agent: user_agent).call
    end

    def initialize(token, verifier_actor:, ip: nil, user_agent: nil)
      @token = token
      @verifier_actor = verifier_actor
      @ip = ip
      @user_agent = user_agent
    end

    def call
      decoded = decode_token
      return reject(reason: "invalid_token") unless decoded

      student_id = decoded[:sub]
      id = StudentId::DigitalStudentId
             .joins(:student)
             .find_by(student_id: student_id, token_hash: Digest::SHA256.hexdigest(@token))

      unless id && id.status == "active" && !id.expired?
        return reject(reason: "revoked_or_expired", digital_id: id)
      end

      id.verification_logs.create!(
        verifier_actor: @verifier_actor.to_s,
        result: true,
        ip_address: @ip,
        user_agent: @user_agent
      )
      { valid: true, student: id.student, digital_id: id }
    rescue JWT::DecodeError, JWT::ExpiredSignature
      reject(reason: "invalid_token")
    end

    private

    def decode_token
      payload, = JWT.decode(@token, secret, true, algorithm: "HS256")
      payload.symbolize_keys
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    def reject(reason:, digital_id: nil)
      if digital_id
        digital_id.verification_logs.create!(
          verifier_actor: @verifier_actor.to_s, result: false,
          ip_address: @ip, user_agent: @user_agent
        )
      end
      { valid: false, reason: reason }
    end

    def secret
      ENV.fetch("OIDC_JWKS_PRIVATE", "dev-insecure-change-me")
    end
  end
end
