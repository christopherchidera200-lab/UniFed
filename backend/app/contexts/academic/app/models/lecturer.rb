module Academic
  class Lecturer < ::ApplicationRecord
    belongs_to :university
    belongs_to :department, optional: true
    has_many :course_offerings, dependent: :nullify

    validates :full_name, presence: true
  end
end
