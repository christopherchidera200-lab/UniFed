module Api
  module V1
    # MFA enrollment + verification management (Phase 0).
    class MfaController < BaseController
      before_action :authenticate!

      # POST /api/v1/mfa/totp/begin  -> {device_id, otpauth_uri, secret}
      def totp_begin
        out = Identity::MfaService.begin_totp(current_user, label: params.dig(:label))
        render json: out.except(:secret).merge(secret: out[:secret]), status: :ok
      end

      # POST /api/v1/mfa/totp/confirm  {device_id, code}
      def totp_confirm
        ok = Identity::MfaService.confirm_totp(current_user, params.dig(:device_id), params.dig(:code))
        return render_unauthorized("invalid_code") unless ok
        Identity::AuditService.log!(action: "mfa.totp_confirmed", actor_type: "user",
          actor_id: current_subject, university_id: current_university&.id, ip: request.remote_ip)
        render json: { ok: true }, status: :ok
      end

      # GET /api/v1/mfa/devices
      def devices
        render json: current_user.mfa_devices.select(:id, :kind, :label, :confirmed, :created_at)
      end
    end
  end
end
