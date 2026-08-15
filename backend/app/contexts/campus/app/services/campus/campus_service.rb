module Campus
  # Campus / Smart-Campus service: create/search campus places and answer
  # "what's near me" queries. No real-time GPS is fabricated — coordinates are
  # operator-supplied; future versions can feed live GPS into the same model.
  class CampusService
    class << self
      def create_place!(university:, campus:, attrs:)
        place = Place.new(attrs.merge(university: university, campus: campus))
        place.save!
        place
      end

      def list(university:, kind: nil, campus_id: nil)
        scope = Place.where(university_id: university.id)
        scope = scope.where(campus_id: campus_id) if campus_id.present?
        scope = scope.of_kind(kind) if kind.present?
        scope.order(:kind, :name)
      end

      # Returns places within `radius_km` of (lat,lng), sorted by distance.
      # Uses a bounding-box pre-filter (PostGIS-independent) + Haversine sort.
      def near(university:, lat:, lng:, radius_km: 5.0, kind: nil)
        scope = Place.where(university_id: university.id)
        scope = scope.of_kind(kind) if kind.present?
        scope = scope.within_box(lat, lng, radius_km)
        scope.select { |p| p.distance_to(lat, lng).to_f <= radius_km.to_f }
              .sort_by { |p| p.distance_to(lat, lng) }
      end

      def find(university:, id:)
        Place.find_by(id: id, university_id: university.id)
      end
    end
  end
end
