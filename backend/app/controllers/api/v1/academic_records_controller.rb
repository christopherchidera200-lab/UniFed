module Api
  module V1
    # Academic Records endpoints (Vertical Slice 1).
    # Authorization: role + owning-university scoped.
    class AcademicRecordsController < BaseController
      before_action :authenticate!
      before_action :load_student, only: %i[show records summary transcript]

      # GET /api/v1/academic/me  -> the current user's own student identity
      # (resolved via the OIDC subject -> Academic::Student.identity_subject).
      def me
        student = Academic::Student.find_by(identity_subject: current_user.id)
        return render json: { error: "no_student" }, status: :not_found unless student
        render json: student_json(student)
      end

      # GET /api/v1/academic/students/:id
      def show
        authorize_student!(@student)
        render json: student_json(@student)
      end

      # GET /api/v1/academic/students/:id/records
      def records
        authorize_student!(@student)
        published = Records::GradeRecord.published_for(@student)
                     .joins(course_offering: { course: :programme })
                     .includes(course_offering: { course: :programme })
        render json: published.map { |g|
          {
            course_code: g.course_offering.course.code,
            course_title: g.course_offering.course.title,
            credit_units: g.course_offering.course.credit_units,
            score: g.score,
            grade_letter: g.grade_letter,
            grade_point: g.grade_point,
            semester: g.course_offering.semester_number
          }
        }
      end

      # GET /api/v1/academic/students/:id/summary
      def summary
        authorize_student!(@student)
        cum = @student.academic_summaries.find_by(academic_session_id: nil)
        render json: {
          matric_no: @student.matric_no,
          cgpa: cum&.cgpa,
          total_credits: cum&.total_credits,
          class_of_degree: cum&.class_of_degree
        }
      end

      # POST /api/v1/academic/students/:id/transcript  -> signed, verifiable transcript
      def transcript
        authorize_student!(@student)
        token = Records::TranscriptService.issue_signed(@student)
        Records::TranscriptIssuance.create!(
          student: @student,
          token_hash: Digest::SHA256.hexdigest(token),
          issued_to: @current_subject || "self",
          purpose: params[:purpose]
        )
        render json: { transcript_jwt: token }
      end

      # POST /api/v1/transcript/verify  (public) -> decode + verify signed transcript
      def verify_transcript
        token = params[:transcript_jwt] || params.dig(:transcript, :jwt)
        return render json: { error: "missing_token" }, status: :bad_request unless token
        result = Records::TranscriptService.verify(token)
        if result.is_a?(Hash) && result[:error]
          render json: { valid: false, error: result[:error] }, status: :unprocessable_entity
        else
          render json: { valid: true, transcript: result }
        end
      end

      private

      def load_student
        @student = Academic::Student.find_by(id: params[:id])
        render json: { error: "not_found" }, status: :not_found unless @student
      end

      # A viewer may see their own record, or staff/admin of the same university.
      def authorize_student!(student)
        staff_or_admin = @current_university == student.university &&
                         (staff? || admin?)
        return if @current_subject == student.identity_subject || staff_or_admin
        render_forbidden
      end

      def staff?  = @current_roles.include?("staff")
      def admin?  = @current_roles.include?("admin")
      def current_roles
        # Resolved from the OIDC token's roles claim in production.
        (decode_bearer(request.authorization.split(" ", 2).last)["roles"] rescue []) || []
      end

      def student_json(s)
        {
          id: s.id, matric_no: s.matric_no, entry_year: s.entry_year,
          entry_mode: s.entry_mode, current_level: s.current_level, status: s.status
        }
      end
    end
  end
end
