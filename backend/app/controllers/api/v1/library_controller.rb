module Api
  module V1
    # Library endpoints (Phase 2 depth): catalogue search, borrow, return.
    class LibraryController < BaseController
      before_action :authenticate!

      # GET /api/v1/library/resources?q=&type=
      def resources
        uni = @current_university
        return render_unauthorized("unknown_node") unless uni
        items = Library::LibraryService.search(uni.id, query: params[:q], type: params[:type])
        render json: items.map { |r|
          { id: r.id, title: r.title, author: r.author, type: r.resource_type,
            available: !r.library_loans.where(status: "borrowed").exists? }
        }
      end

      # POST /api/v1/library/borrow  { library_resource_id }
      def borrow
        student = current_student
        return render_unauthorized("no_student_link") unless student
        resource = Library::LibraryResource.find_by(id: params[:library_resource_id])
        return render json: { error: "not_found" }, status: :not_found unless resource
        begin
          loan = Library::LibraryService.borrow!(student: student, library_resource: resource)
          render json: { loan_id: loan.id, status: loan.status }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/library/return  { loan_id }
      def return_resource
        loan = Library::LibraryLoan.find_by(id: params[:loan_id])
        return render json: { error: "not_found" }, status: :not_found unless loan
        returned = Library::LibraryService.return!(loan: loan)
        render json: { loan_id: returned.id, status: returned.status }
      end

      private

      def current_student
        return nil unless @current_subject
        Academic::Student.find_by(identity_subject: @current_subject)
      end
    end
  end
end
