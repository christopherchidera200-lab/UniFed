# OIDC issuer endpoints (Phase 0 hardening). Mounted at root scope.
# Discovery + JWKS + token (password/refresh grants) + userinfo.
class OidcController < ActionController::API
  # GET /.well-known/openid-configuration
  def configuration
    render json: Identity::OidcIssuerService.discovery
  end

  # GET /.well-known/jwks.json
  def jwks
    render json: { keys: [Identity::OidcKeyService.jwk] }
  end

  # POST /oauth/token
  def token
    grant = params[:grant_type]
    case grant
    when "password"
      out = Identity::OidcIssuerService.password_grant(
        username: params[:username], password: params[:password], audience: params[:audience]
      )
      out[:error] ? render(json: { error: out[:error] }, status: :bad_request) : render(json: out)
    when "refresh_token"
      out = Identity::OidcIssuerService.refresh_grant(refresh_token: params[:refresh_token], audience: params[:audience])
      out[:error] ? render(json: { error: out[:error] }, status: :bad_request) : render(json: out)
    else
      render json: { error: "unsupported_grant_type" }, status: :bad_request
    end
  end

  # GET /oauth/userinfo  (Bearer access token)
  def userinfo
    token = bearer_token
    claims = token && Identity::OidcIssuerService.userinfo(token)
    claims ? render(json: claims) : render(json: { error: "invalid_token" }, status: :unauthorized)
  end

  private

  def bearer_token
    header = request.headers["Authorization"].to_s
    header.start_with?("Bearer ") ? header[7..] : nil
  end
end
