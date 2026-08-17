module Api
  module V1
    # NDPA consent management (Phase 0). Users manage their own consent ledger.
    class ConsentController < BaseController
      before_action :authenticate!

      # GET /api/v1/consent
      def index
        render json: current_user.consent_records.select(
          :id, :purpose, :granted, :consent_version, :granted_at, :withdrawn_at, :created_at
        )
      end

      # POST /api/v1/consent  {purpose, granted, version?}
      def create
        purpose = params.dig(:purpose)
        return render json: { error: "purpose_required" }, status: :bad_request unless purpose
        granted = ActiveModel::Type::Boolean.new.cast(params.dig(:granted))
        version = params.dig(:version).presence || UniFed::Application.config.x.consent_policy_version
        rec = current_user.consent_records.find_or_initialize_by(purpose: purpose)
        rec.granted = granted
        rec.consent_version = version
        rec.granted_at = granted ? Time.current : nil
        rec.withdrawn_at = granted ? nil : Time.current
        rec.save!
        render json: {
          ok: true, purpose: purpose, granted: rec.granted,
          version: rec.consent_version, granted_at: rec.granted_at, withdrawn: rec.withdrawn?
        }, status: :ok
      end
    end
  end
end
