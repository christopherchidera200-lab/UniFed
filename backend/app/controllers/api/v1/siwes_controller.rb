module Api
  module V1
    # SIWES / Internship tracking endpoints (Phase 2).
    class SiwesController < BaseController
      before_action :authenticate!

      # POST /api/v1/siwes/placement  (student starts/updates a placement)
      # body: { academic_session_id, employer_name, supervisor_name,
      #         supervisor_email, start_date, end_date }
      def placement
        student = current_student
        return render_unauthorized("no_student_link") unless student
        placement = Siwes::SiwesService.ensure_placement!(
          student: student, academic_session_id: params[:academic_session_id],
          employer_name: params[:employer_name], supervisor_name: params[:supervisor_name],
          supervisor_email: params[:supervisor_email], start_date: params[:start_date],
          end_date: params[:end_date]
        )
        render json: { placement_id: placement.id, status: placement.status }, status: :created
      end

      # POST /api/v1/siwes/logs  (student submits a weekly log)
      def logs
        student = current_student
        return render_unauthorized("no_student_link") unless student
        placement = Siwes::SiwesPlacement.find_by(id: params[:placement_id], student: student)
        return render json: { error: "not_found" }, status: :not_found unless placement
        log = placement.siwes_logs.create!(
          week_number: params[:week_number], hours: params[:hours],
          task_summary: params[:task_summary], status: "submitted"
        )
        render json: { log_id: log.id, week: log.week_number }, status: :created
      end

      # POST /api/v1/siwes/logs/:id/verify  (supervisor verifies)
      def verify_log
        log = Siwes::SiwesLog.find_by(id: params[:id])
        return render json: { error: "not_found" }, status: :not_found unless log
        verified = Siwes::SiwesService.verify_log!(log_id: log.id, verified_by: @current_subject)
        render json: { log_id: verified.id, status: verified.status }
      end

      # GET /api/v1/siwes/completion?placement_id=
      def completion
        placement = Siwes::SiwesPlacement.find_by(id: params[:placement_id])
        return render json: { error: "not_found" }, status: :not_found unless placement
        render json: Siwes::SiwesService.completion_status(placement)
      end

      private

      def current_student
        return nil unless @current_subject
        Academic::Student.find_by(identity_subject: @current_subject)
      end
    end
  end
end
