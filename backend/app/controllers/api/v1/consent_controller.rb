module Api
  module V1
    # NDPA consent management (Phase 0). Users manage their own consent ledger.
    class ConsentController < BaseController
      before_action :authenticate!

      # GET /api/v1/consent
      def index
        render json: current_user.consent_records.select(:id, :purpose, :granted, :withdrawn_at, :created_at)
      end

      # POST /api/v1/consent  {purpose, granted}
      def create
        purpose = params.dig(:purpose)
        granted = params.dig(:granted)
        return render json: { error: "purpose_required" }, status: :bad_request unless purpose
        rec = current_user.consent_records.find_or_initialize_by(purpose: purpose)
        if granted
          rec.withdrawn_at = nil
          rec.granted = true
          rec.save!
        else
          rec.grant! if rec.new_record?
          rec.withdraw!
        end
        render json: { ok: true, purpose: purpose, granted: rec.granted?, withdrawn: rec.withdrawn? }, status: :ok
      end
    end
  end
end
