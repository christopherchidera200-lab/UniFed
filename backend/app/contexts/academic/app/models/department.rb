module Academic
  class Department < ApplicationRecord
    belongs_to :faculty
    has_one  :university, through: :faculty
    has_many :programmes, dependent: :destroy

    validates :code, presence: true, uniqueness: { scope: :faculty_id }
    validates :name, presence: true
  end
end
