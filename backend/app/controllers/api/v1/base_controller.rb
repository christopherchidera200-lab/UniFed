module Api
  module V1
    # Base controller: enforces OIDC bearer auth (ADR-0004), exposes current
    # subject + owning-university scope. All slice controllers inherit from this.
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      attr_reader :current_subject, :current_university

      protected

      def authenticate!
        token = request.authorization&.split(" ", 2)&.last
        return render_unauthorized("missing_token") unless token

        payload = decode_bearer(token)
        return render_unauthorized("invalid_token") unless payload

        @current_subject    = payload["sub"]
        @current_university = Academic::University.find_by(slug: payload["uni"])
        render_unauthorized("unknown_node") unless @current_university
      end

      def decode_bearer(token)
        # Local verification of the node's own OIDC JWT (HS256 dev / RS256 prod).
        JWT.decode(token, jwt_secret, true, algorithm: "HS256").first
      rescue JWT::DecodeError, JWT::ExpiredSignature
        nil
      end

      def jwt_secret
        ENV.fetch("OIDC_JWKS_PRIVATE", "dev-insecure-change-me")
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
