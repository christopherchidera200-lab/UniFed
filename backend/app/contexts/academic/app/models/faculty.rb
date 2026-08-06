module Academic
  class Faculty < ApplicationRecord
    belongs_to :university
    has_many :departments, dependent: :destroy

    validates :code, presence: true, uniqueness: { scope: :university_id }
    validates :name, presence: true
  end
end
