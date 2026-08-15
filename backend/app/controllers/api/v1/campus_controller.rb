module Api
  module V1
    # Campus / Smart-Campus discovery. Public-read (node-scoped) but writes
    # require staff/admin RBAC. No federation exposure of internal locations.
    class CampusController < Api::V1::BaseController
      # GET /api/v1/campus/places?kind=&campus_id=
      def index
        places = Campus::CampusService.list(
          university: current_university,
          kind: params[:kind],
          campus_id: params[:campus_id]
        )
        render json: places.map { |p| place_json(p) }
      end

      # GET /api/v1/campus/places/:id
      def show
        place = Campus::CampusService.find(university: current_university, id: params[:id])
        return render json: { error: "not_found" }, status: :not_found unless place
        render json: place_json(place)
      end

      # GET /api/v1/campus/near?lat=&lng=&radius=&kind=
      def near
        lat = params[:lat].to_f
        lng = params[:lng].to_f
        radius = (params[:radius] || 5).to_f
        places = Campus::CampusService.near(
          university: current_university, lat: lat, lng: lng, radius_km: radius, kind: params[:kind]
        )
        render json: places.map { |p| place_json(p).merge(distance_km: p.distance_to(lat, lng)) }
      end

      # POST /api/v1/campus/places  (staff/admin)
      def create
        return render_forbidden unless current_user&.has_permission?("campus:manage")
        campus = Campus::Campus.find_by(id: place_params[:campus_id], university_id: current_university.id)
        return render json: { error: "campus_not_found" }, status: :not_found unless campus
        place = Campus::CampusService.create_place!(
          university: current_university, campus: campus, attrs: place_params.except(:campus_id)
        )
        render json: place_json(place), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def place_params
        params.require(:place).permit(:campus_id, :name, :kind, :description, :lat, :lng, :accessibility_level, metadata: {})
      end

      def place_json(p)
        {
          id: p.id, campus_id: p.campus_id, university_id: p.university_id,
          name: p.name, kind: p.kind, description: p.description,
          lat: p.lat, lng: p.lng, accessibility_level: p.accessibility_level,
          metadata: p.metadata
        }
      end
    end
  end
end
