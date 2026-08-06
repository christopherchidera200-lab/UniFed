module Academic
  class StudentEnrollment < ApplicationRecord
    belongs_to :student
    belongs_to :programme
    belongs_to :academic_session

    validates :student_id, uniqueness: { scope: %i[programme_id academic_session_id] }
  end
end
