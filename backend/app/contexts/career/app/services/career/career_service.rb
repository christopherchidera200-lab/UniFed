module Career
  # Domain service for the Career Hub: posting opportunities, applying,
  # saving/bookmarking, and matching opportunities to a student's profile.
  class CareerService
    # List open opportunities with optional filters (keyword, type, level).
    def self.search(filters = {})
      scope = CareerOpportunity.open
      scope = scope.where(employment_type: filters[:employment_type]) if filters[:employment_type]
      scope = scope.where(location_type: filters[:location_type]) if filters[:location_type]
      scope = scope.for_level(filters[:level]) if filters[:level]
      if filters[:q].present?
        like = "%#{filters[:q]}%"
        scope = scope.where("title ILIKE ? OR description ILIKE ?", like, like)
      end
      scope.order(created_at: :desc)
    end

    # A student applies to an opportunity (idempotent create).
    def self.apply!(student:, opportunity:, cover_note: nil)
      application = CareerApplication.find_by(student: student, career_opportunity: opportunity)
      return application if application
      CareerApplication.create!(
        student: student,
        career_opportunity: opportunity,
        cover_note: cover_note,
        status: "submitted"
      )
    end

    # Toggle a saved/bookmarked job for a student.
    def self.toggle_save!(student:, opportunity:)
      saved = SavedJob.find_by(student: student, career_opportunity: opportunity)
      if saved
        saved.destroy!
        return { saved: false }
      end
      SavedJob.create!(student: student, career_opportunity: opportunity)
      { saved: true }
    end

    # Opportunities recommended for a student based on level + programme.
    def self.recommend_for(student)
      return CareerOpportunity.open.none if student.nil?
      CareerOpportunity.open
        .for_level(student.current_level)
        .order(created_at: :desc)
        .limit(20)
    end
  end
end
