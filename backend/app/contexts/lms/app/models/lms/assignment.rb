module Lms
  # A course assignment authored by a lecturer for a CourseOffering.
  class Assignment < ::ApplicationRecord
    self.table_name = "lms_assignments"

    belongs_to :course_offering, class_name: "Academic::CourseOffering"
    belongs_to :lecturer, class_name: "Academic::Lecturer"
    has_many :submissions, class_name: "Lms::Submission", inverse_of: :assignment, dependent: :destroy

    validates :title, presence: true
    validates :max_score, numericality: { greater_than: 0 }, allow_nil: true

    scope :published, -> { where(published: true) }
  end
end
