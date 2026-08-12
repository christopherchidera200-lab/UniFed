module Api
  module V1
    # Base controller: enforces OIDC bearer auth (ADR-0004), exposes current
    # subject + owning-university scope, and provides RBAC enforcement. All
    # slice controllers inherit from this.
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate!

      attr_reader :current_subject, :current_university, :jwt_payload, :current_user

      protected

      def authenticate!
        token = request.authorization&.split(" ", 2)&.last
        return render_unauthorized("missing_token") unless token

        @jwt_payload = decode_bearer(token)
        return render_unauthorized("invalid_token") unless @jwt_payload

        @current_subject    = @jwt_payload["sub"]
        @current_university = Academic::University.find_by(slug: @jwt_payload["uni"])
        return render_unauthorized("unknown_node") unless @current_university

        # Resolve the full user for RBAC / audit convenience.
        @current_user = Identity::User.find_by(id: @current_subject)
      end

      def decode_bearer(token)
        Identity::TokenService.verify(token, type: "access")
      end

      # RBAC gate used by admin-scoped controllers.
      def require_permission
        authenticate!
        return render_forbidden unless current_user&.has_permission?("admin:users") ||
                                       current_user&.admin?
      end

      def jwt_secret
        Identity::TokenService.secret
      end

      def render_unauthorized(reason)
        render json: { error: "unauthorized", reason: reason }, status: :unauthorized
      end

      def render_forbidden
        render json: { error: "forbidden" }, status: :forbidden
      end
    end
  end
end
