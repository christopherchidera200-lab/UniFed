module Academic
  class Semester < ::ApplicationRecord
    belongs_to :academic_session
    has_one  :university, through: :academic_session
    has_many :course_offerings, dependent: :destroy

    validates :number, inclusion: { in: [1, 2] }
    validates :lecture_start, presence: true
    validates :lecture_end, presence: true
    validates :exam_start, presence: true
    validates :exam_end, presence: true
    validate :windows_order

    scope :for_session, ->(session) { where(academic_session: session) }

    # Is a given date inside the active lecture period of this semester?
    def lecturing_on?(date)
      (lecture_start..lecture_end).cover?(date)
    end

    private

    def windows_order
      return if [lecture_start, lecture_end, exam_start, exam_end].any?(&:nil?)
      errors.add(:base, "lecture_end must be >= lecture_start") if lecture_end < lecture_start
      errors.add(:base, "exam_end must be >= exam_start")       if exam_end < exam_start
      errors.add(:base, "exam_start must be after lecture_end") if exam_start < lecture_end
    end
  end
end
