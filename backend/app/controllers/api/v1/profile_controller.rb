module Api
  module V1
    # Profile tab: read/update the extended profile (bio, skills, portfolio, etc.)
    class ProfileController < BaseController
      before_action :authenticate!

      # GET /api/v1/profile  (current user's composed profile)
      def show
        render json: Profile::ProfileService.for_user(current_user)
      end

      # PATCH /api/v1/profile  {bio, skills, portfolio, social_links, creator}
      def update
        render json: Profile::ProfileService.update(current_user, params.permit(:bio, :skills, :portfolio, :social_links, :creator).to_h), status: :ok
      end
    end
  end
end
