module Academic
  class CourseOffering < ::ApplicationRecord
    belongs_to :course
    belongs_to :academic_session
    belongs_to :lecturer, optional: true
    has_many :grade_records, dependent: :destroy

    validates :semester_number, inclusion: { in: [1, 2] }
    validates :course_id, uniqueness: { scope: %i[academic_session_id semester_number] }
  end
end
