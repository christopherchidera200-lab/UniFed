module Career
  # A student's saved/bookmarked opportunity (watchlist).
  class SavedJob < ::ApplicationRecord
    belongs_to :student, class_name: "Academic::Student"
    belongs_to :career_opportunity

    validates :student_id, uniqueness: { scope: :career_opportunity_id }
  end
end
