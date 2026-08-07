module Academic
  class Programme < ::ApplicationRecord
    belongs_to :department
    has_many :courses, dependent: :destroy
    has_many :student_enrollments, dependent: :restrict_with_error

    validates :code, presence: true, uniqueness: { scope: :department_id }
    validates :name, presence: true
    validates :degree_type, inclusion: {
      in: %w[B.Sc B.Eng B.A LL.B M.Sc Ph.D PGD]
    }
    validates :duration_years, numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  end
end
