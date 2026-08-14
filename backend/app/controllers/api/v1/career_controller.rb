module Api
  module V1
    # Career Hub endpoints (Phase 2).
    class CareerController < BaseController
      skip_before_action :authenticate!, only: %i[opportunities]

      # GET /api/v1/career/opportunities?employment_type=&location_type=&level=&q=  (public browse)
      def opportunities
        opps = Career::CareerService.search(index_filters)
        render json: opps.map { |o| opportunity_json(o) }
      end

      # GET /api/v1/career/recommendations
      def recommendations
        student = current_student
        return render_unauthorized("no_student_link") unless student
        recs = Career::CareerService.recommend_for(student)
        render json: recs.map { |o| opportunity_json(o) }
      end

      # POST /api/v1/career/opportunities/:id/apply
      def apply
        opp = CareerOpportunity.find_by(id: params[:id], status: "open")
        return render json: { error: "not_found" }, status: :not_found unless opp
        student = current_student
        return render_unauthorized("no_student_link") unless student
        application = Career::CareerService.apply!(
          student: student, opportunity: opp, cover_note: params[:cover_note]
        )
        render json: { application_id: application.id, status: application.status }, status: :created
      end

      # POST /api/v1/career/opportunities/:id/save
      def save_job
        opp = CareerOpportunity.find_by(id: params[:id])
        return render json: { error: "not_found" }, status: :not_found unless opp
        student = current_student
        return render_unauthorized("no_student_link") unless student
        result = Career::CareerService.toggle_save!(student: student, opportunity: opp)
        render json: result
      end

      # GET /api/v1/career/applications  (the current student's applications)
      def applications
        student = current_student
        return render_unauthorized("no_student_link") unless student
        apps = student.career_applications.includes(:career_opportunity).order(created_at: :desc)
        render json: apps.map { |a|
          { id: a.id, status: a.status, opportunity: opportunity_json(a.career_opportunity) }
        }
      end

      private

      def index_filters
        {
          employment_type: params[:employment_type],
          location_type: params[:location_type],
          level: params[:level]&.to_i,
          q: params[:q]
        }.compact
      end

      def current_student
        return nil unless @current_subject
        Academic::Student.find_by(identity_subject: @current_subject)
      end

      def opportunity_json(o)
        {
          id: o.id, title: o.title, employment_type: o.employment_type,
          location_type: o.location_type, location: o.location, remote: o.remote,
          min_level: o.min_level, salary_range: o.salary_range,
          employer: o.employer_profile&.name, created_at: o.created_at
        }
      end
    end
  end
end
