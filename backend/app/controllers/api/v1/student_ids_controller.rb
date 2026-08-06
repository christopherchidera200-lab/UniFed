module Api
  module V1
    # Digital Student ID endpoints (Vertical Slice 1).
    class StudentIdsController < BaseController
      before_action :authenticate!

      # POST /api/v1/student-id/:student_id/issue  (staff/admin only)
      def issue
        student = Academic::Student.find_by(id: params[:student_id])
        return render json: { error: "not_found" }, status: :not_found unless student

        unless student.university == @current_university && (staff? || admin?)
          return render_forbidden
        end

        result = StudentId::IdIssuanceService.issue!(student, issued_by: @current_subject)
        render json: {
          id: result[:digital_id].id,
          status: result[:digital_id].status,
          issued_at: result[:digital_id].issued_at,
          expires_at: result[:digital_id].expires_at,
          token: result[:token],           # one-time; client must store securely
          qr_payload: result[:digital_id].qr_payload
        }, status: :created
      end

      # POST /api/v1/student-id/verify  (offline-friendly scan verification)
      def verify
        token = params.dig(:token)
        return render json: { error: "missing_token" }, status: :bad_request unless token

        outcome = StudentId::IdVerificationService.verify!(
          token,
          verifier_actor: @current_subject || "self",
          ip: request.remote_ip,
          user_agent: request.user_agent
        )
        if outcome[:valid]
          render json: { valid: true, student: {
            matric_no: outcome[:student].matric_no,
            level: outcome[:student].current_level,
            status: outcome[:student].status
          } }
        else
          render json: { valid: false, reason: outcome[:reason] }, status: :unauthorized
        end
      end

      private

      def staff?  = roles.include?("staff")
      def admin?  = roles.include?("admin")
      def roles
        (decode_bearer(request.authorization.split(" ", 2).last)["roles"] rescue []) || []
      end
    end
  end
end
