module Campus
  # A point of interest on a campus (lecture hall, lab, library, hostel,
  # cafeteria, medical centre, security office, parking, shuttle stop,
  # event location, faculty, department, etc.).
  #
  # Geographic data is always stored as decimal lat/lng (PostGIS-independent).
  # If the postgis extension is present, a `location geography(Point,4326)`
  # column also exists for future spatial queries.
  class Place < ::ApplicationRecord
    self.table_name = "campus_places"

    KINDS = %w[
      university campus building lecture_hall laboratory library hostel
      cafeteria medical_centre security_office parking shuttle_stop
      event_location faculty department other
    ].freeze

    belongs_to :university, class_name: "Academic::University"
    belongs_to :campus, class_name: "Campus::Campus", inverse_of: :places

    validates :name, presence: true
    validates :kind, presence: true, inclusion: { in: KINDS }
    validates :lat, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
    validates :lng, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

    scope :of_kind, ->(kind) { where(kind: kind) }
    scope :within_box, lambda { |lat, lng, radius_km|
      # Approx degree deltas for a bounding-box pre-filter (fast, no PostGIS).
      d_lat = radius_km.fdiv(110.574)
      d_lng = radius_km.fdiv(111.320 * Math.cos(lat * Math::PI / 180).clamp(0.01, 1))
      where(lat: (lat - d_lat)..(lat + d_lat), lng: (lng - d_lng)..(lng + d_lng))
    }

    # Great-circle distance in kilometres (Haversine). Pure Ruby/SQL — works
    # without PostGIS, so staging stays runnable.
    def distance_to(lat, lng)
      return nil if lat.nil? || lng.nil? || self.lat.nil? || self.lng.nil?
      r = 6371.0
      d_lat = (self.lat - lat) * Math::PI / 180
      d_lng = (self.lng - lng) * Math::PI / 180
      a = Math.sin(d_lat / 2)**2 +
          Math.cos(lat * Math::PI / 180) * Math.cos(self.lat * Math::PI / 180) * Math.sin(d_lng / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      (r * c).round(3)
    end
  end
end
