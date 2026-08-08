module Api
  module V1
    # Course Catalogue / browse endpoints (Phase 2).
    class CatalogController < BaseController
      before_action :authenticate!

      # GET /api/v1/catalog/courses?programme_id=&level=&semester=&q=
      def courses
        result = Catalog::CourseCatalogService.courses(course_filters)
        render json: result.map { |c|
          {
            id: c.id, code: c.code, title: c.title,
            credit_units: c.credit_units, level: c.level, semester: c.semester,
            programme_id: c.programme_id, prerequisites: c.prerequisites
          }
        }
      end

      # GET /api/v1/catalog/offerings?academic_session_id=&course_id=
      def offerings
        session_id = params[:academic_session_id]
        return render json: { error: "academic_session_id_required" }, status: :bad_request unless session_id
        result = Catalog::CourseCatalogService.offerings(
          academic_session_id: session_id, course_id: params[:course_id]
        )
        render json: result.map { |o|
          {
            id: o.id, course_code: o.course.code, course_title: o.course.title,
            semester_number: o.semester_number,
            lecturer: o.lecturer&.full_name
          }
        }
      end

      private

      def course_filters
        {
          programme_id: params[:programme_id],
          level: params[:level]&.to_i,
          semester: params[:semester]&.to_i,
          q: params[:q]
        }.compact
      end
    end
  end
end
