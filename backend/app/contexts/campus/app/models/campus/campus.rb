module Campus
  # A campus belonging to a university. Groups physical Places.
  class Campus < ::ApplicationRecord
    self.table_name = "campus_campuses"
    belongs_to :university, class_name: "Academic::University"
    has_many :places, class_name: "Campus::Place", inverse_of: :campus, dependent: :destroy

    validates :name, presence: true
    validates :center_lat, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
    validates :center_lng, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  end
end
