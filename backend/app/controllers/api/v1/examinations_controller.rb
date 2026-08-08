module Api
  module V1
    # Examination scheduling endpoints (Phase 2 depth).
    class ExaminationsController < BaseController
      before_action :authenticate!

      # GET /api/v1/examinations?course_offering_id=
      def index
        uni = @current_university
        return render_unauthorized("unknown_node") unless uni
        exams = Examination::ExamService.upcoming(uni.id, course_offering_id: params[:course_offering_id])
        render json: exams.map { |e|
          { id: e.id, exam_type: e.exam_type, starts_at: e.starts_at, ends_at: e.ends_at,
            venue: e.venue, invigilator: e.invigilator, course_offering_id: e.course_offering_id }
        }
      end
    end
  end
end
