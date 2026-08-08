module Catalog
  # Read/query service over the course catalogue and offerings. The catalogue
  # data comes from Registry exports (Academic context owns the tables); this
  # context only provides student-facing browse + filter behaviour.
  class CourseCatalogService
    # Browse courses with optional filters (programme, level, semester, keyword).
    def self.courses(filters = {})
      scope = Academic::Course.all
      scope = scope.where(programme_id: filters[:programme_id]) if filters[:programme_id]
      scope = scope.where(level: filters[:level]) if filters[:level]
      scope = scope.where(semester: filters[:semester]) if filters[:semester]
      if filters[:q].present?
        like = "%#{filters[:q]}%"
        scope = scope.where("code ILIKE ? OR title ILIKE ?", like, like)
      end
      scope.order(:level, :code)
    end

    # List offerings for a session, optionally scoped to a course.
    def self.offerings(academic_session_id:, course_id: nil)
      scope = Academic::CourseOffering.where(academic_session_id: academic_session_id)
      scope = scope.where(course_id: course_id) if course_id
      scope.includes(:course, :lecturer).order("courses.level", "courses.code")
    end

    # Programme -> course list (for a department's plan of study).
    def self.for_programme(programme_id)
      courses(programme_id: programme_id)
    end
  end
end
