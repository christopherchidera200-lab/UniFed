module Api
  module V1
    # Assignments / LMS. Lecturers author + grade; students submit. AI grading is
    # advisory only (lecturer confirms). Strict ownership enforced throughout.
    class AssignmentsController < Api::V1::BaseController
      # GET /api/v1/assignments  (student: my courses; lecturer: taught offerings)
      #   ?course_offering_id= filters (lecturer-owned offerings only)
      def index
        if current_lecturer
          scope = Lms::Assignment.where(lecturer_id: current_lecturer.id)
          scope = scope.where(course_offering_id: params[:course_offering_id]) if params[:course_offering_id].present?
          render json: scope.order(created_at: :desc).map { |a| assignment_json(a) }
        else
          student = current_student
          return render_unauthorized("not_a_student") unless student
          render json: Lms::AssignmentService.for_student(student: student).map { |a| assignment_json(a, student) }
        end
      end

      # GET /api/v1/assignments/:id
      def show
        assignment = Lms::Assignment.find_by(id: params[:id])
        return render json: { error: "not_found" }, status: :not_found unless assignment
        student = current_student
        render json: assignment_json(assignment, student)
      end

      # POST /api/v1/assignments  (lecturer, academic:write)
      def create
        lecturer = current_lecturer
        return render_forbidden unless lecturer && current_user&.has_permission?("academic:write")
        offering = Academic::CourseOffering.find_by(id: assignment_params[:course_offering_id])
        return render json: { error: "offering_not_found" }, status: :not_found unless offering
        assignment = Lms::AssignmentService.create!(
          lecturer: lecturer, course_offering: offering,
          attrs: assignment_params.except(:course_offering_id)
        )
        render json: assignment_json(assignment), status: :created
      rescue ArgumentError => e
        status = e.message.include?("teach") ? :forbidden : :unprocessable_entity
        render json: { error: e.message }, status: status
      end

      # POST /api/v1/assignments/:id/submit  (student)
      def submit
        student = current_student
        return render_unauthorized("not_a_student") unless student
        assignment = Lms::Assignment.find_by(id: params[:id])
        return render json: { error: "not_found" }, status: :not_found unless assignment
        submission = Lms::AssignmentService.submit!(
          student: student, assignment: assignment,
          attrs: { body: params[:body], attachment_ref: params[:attachment_ref] }
        )
        render json: submission_json(submission), status: :created
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # PATCH /api/v1/assignments/:id/submissions/:submission_id  (lecturer grade)
      def grade
        lecturer = current_lecturer
        return render_forbidden unless lecturer
        assignment = Lms::Assignment.find_by(id: params[:id])
        return render json: { error: "not_found" }, status: :not_found unless assignment
        return render_forbidden unless assignment.lecturer_id == lecturer.id
        submission = assignment.submissions.find_by(id: params[:submission_id])
        return render json: { error: "not_found" }, status: :not_found unless submission
        submission = Lms::AssignmentService.grade!(
          submission: submission, lecturer: lecturer,
          score: params[:score], feedback: params[:feedback]
        )
        render json: submission_json(submission)
      end

      # GET /api/v1/assignments/:id/submissions  (lecturer)
      def submissions
        lecturer = current_lecturer
        return render_forbidden unless lecturer
        assignment = Lms::Assignment.find_by(id: params[:id])
        return render json: { error: "not_found" }, status: :not_found unless assignment
        return render_forbidden unless assignment.lecturer_id == lecturer.id
        list = Lms::AssignmentService.submissions_for(assignment: assignment, lecturer: lecturer)
        render json: list.map { |s| submission_json(s) }
      end

      private

      def current_lecturer
        return nil unless current_user&.actor_type == "staff"
        Academic::Lecturer.find_by(id: current_user.actor_id)
      end

      def current_student
        return nil unless current_user&.actor_type == "student"
        Academic::Student.find_by(identity_subject: current_user.id)
      end

      def assignment_params
        params.require(:assignment).permit(:course_offering_id, :title, :description, :instructions, :rubric, :max_score, :due_at, :published)
      end

      def assignment_json(a, student = nil)
        h = {
          id: a.id, course_offering_id: a.course_offering_id, lecturer_id: a.lecturer_id,
          title: a.title, description: a.description, instructions: a.instructions,
          max_score: a.max_score, due_at: a.due_at, published: a.published
        }
        if student
          sub = a.submissions.find_by(student_id: student.id)
          h[:my_submission] = sub ? submission_json(sub) : nil
        end
        h
      end

      def submission_json(s)
        {
          id: s.id, assignment_id: s.assignment_id, student_id: s.student_id,
          status: s.status, score: s.score, feedback: s.feedback,
          submitted_at: s.submitted_at, attachment_ref: s.attachment_ref
        }
      end
    end
  end
end
