module Api
  module V1
    # Notifications endpoints (Phase 2 depth).
    class NotificationsController < BaseController
      before_action :authenticate!

      # GET /api/v1/notifications  (unread for the calling user)
      def index
        user = current_user
        items = Notification::NotificationService.unread_for(user: user)
        render json: items.map { |n|
          { id: n.id, category: n.category, title: n.title, body: n.body, created_at: n.created_at }
        }
      end

      # POST /api/v1/notifications/:id/read
      # Ownership-scoped (F-09): a user may only mark THEIR OWN notification read.
      def read
        item = Notification::NotificationService.unread_for(user: current_user)
                                     .find_by(id: params[:id])
        return render json: { error: "not_found" }, status: :not_found unless item
        Notification::NotificationService.mark_read!(id: item.id)
        render json: { id: item.id, status: item.status }
      end

      private

      def current_user
        @current_user
      end
    end
  end
end
