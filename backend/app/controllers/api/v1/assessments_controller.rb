module Api
  module V1
    # Assessment endpoints (Phase 2): record component scores and roll up
    # into the canonical grade record. Staff/admin of the owning university.
    class AssessmentsController < BaseController
      before_action :authenticate!

      # POST /api/v1/assessments/record
      # body: { student_id, course_offering_id, component, score, weight? }
      def record
        student = Academic::Student.find_by(id: params[:student_id])
        offering = Academic::CourseOffering.find_by(id: params[:course_offering_id])
        return render json: { error: "not_found" }, status: :not_found unless student && offering
        return render_forbidden unless staff_of?(student.university)

        rec = Assessment::AssessmentService.record!(
          student: student, course_offering: offering,
          component: params[:component], score: params[:score].to_f,
          weight: params[:weight]&.to_f, recorded_by: @current_subject
        )
        render json: { id: rec.id, component: rec.component, score: rec.score }, status: :created
      end

      # POST /api/v1/assessments/rollup
      # body: { student_id, course_offering_id, publish? }
      def rollup
        student = Academic::Student.find_by(id: params[:student_id])
        offering = Academic::CourseOffering.find_by(id: params[:course_offering_id])
        return render json: { error: "not_found" }, status: :not_found unless student && offering
        return render_forbidden unless staff_of?(student.university)

        grade = Assessment::AssessmentService.rollup!(
          student: student, course_offering: offering,
          publish: params[:publish].present?, recorded_by: @current_subject
        )
        render json: { grade_record_id: grade&.id, score: grade&.score, published: grade&.is_published }
      end

      private

      def staff_of?(university)
        @current_university == university && (staff? || admin?)
      end

      def staff?  = @current_roles.include?("staff")
      def admin?  = @current_roles.include?("admin")
      def current_roles
        (decode_bearer(request.authorization.split(" ", 2).last)["roles"] rescue []) || []
      end
    end
  end
end
