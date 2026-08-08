module Career
  # A student's application to a career opportunity.
  class CareerApplication < ::ApplicationRecord
    belongs_to :student, class_name: "Academic::Student"
    belongs_to :career_opportunity
    belongs_to :employer_profile, optional: true # denormalized for listing

    validates :student_id, uniqueness: { scope: :career_opportunity_id }
    validates :status, inclusion: {
      in: %w[submitted under_review shortlisted interview offer rejected withdrawn]
    }

    before_validation :set_employer, on: :create

    private

    def set_employer
      self.employer_profile_id ||= career_opportunity&.employer_profile_id
    end
  end
end
