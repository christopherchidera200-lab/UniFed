require "rails_helper"

RSpec.describe Identity::OidcIssuerService, type: :service do
  let(:university) { create(:university) }
  let(:user) { create(:identity_user, university: university, skip_password: true) }
  let(:password) { "Sup3rSecret!Pass" }

  before do
    # Set a real password via the credential factory path.
    user.credentials.create!(kind: "password", secret_enc: Identity::Credential.hash_password(password))
  end

  it "exposes discovery metadata with RS256 and endpoints" do
    disc = Identity::OidcIssuerService.discovery
    expect(disc[:issuer]).to eq(UniFed::Application.config.x.oidc_issuer)
    expect(disc[:jwks_uri]).to end_with("/.well-known/jwks.json")
    expect(disc[:id_token_signing_alg_values_supported]).to include("RS256")
  end

  it "issues access + id + refresh tokens via password grant" do
    out = Identity::OidcIssuerService.password_grant(username: user.email, password: password)
    expect(out[:error]).to be_nil
    expect(out[:access_token]).to be_present
    expect(out[:id_token]).to be_present
    expect(out[:refresh_token]).to be_present
    expect(out[:token_type]).to eq("Bearer")
  end

  it "rejects a wrong password" do
    out = Identity::OidcIssuerService.password_grant(username: user.email, password: "wrong")
    expect(out[:error]).to eq(:invalid_credentials)
  end

  it "returns userinfo claims for a valid access token" do
    out = Identity::OidcIssuerService.password_grant(username: user.email, password: password)
    claims = Identity::OidcIssuerService.userinfo(out[:access_token])
    expect(claims[:sub]).to eq(user.id)
    expect(claims[:email]).to eq(user.email)
  end

  it "refreshes tokens with the refresh grant" do
    out = Identity::OidcIssuerService.password_grant(username: user.email, password: password)
    refreshed = Identity::OidcIssuerService.refresh_grant(refresh_token: out[:refresh_token])
    expect(refreshed[:error]).to be_nil
    expect(refreshed[:access_token]).to be_present
  end

  it "produces a verifiable JWK" do
    jwk = Identity::OidcKeyService.jwk
    expect(jwk[:kty]).to eq("RSA")
    expect(jwk[:alg]).to eq("RS256")
    expect(jwk[:n]).to be_present
    expect(jwk[:e]).to eq(Identity::OidcKeyService.jwk[:e])
  end
end

RSpec.describe "OIDC controller", type: :request do
  let(:university) { create(:university) }
  let(:user) { create(:identity_user, university: university, skip_password: true) }

  before do
    user.credentials.create!(kind: "password", secret_enc: Identity::Credential.hash_password("Sup3rSecret!Pass"))
  end

  it "serves openid-configuration and jwks" do
    get "/.well-known/openid-configuration"
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["issuer"]).to eq(UniFed::Application.config.x.oidc_issuer)

    get "/.well-known/jwks.json"
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["keys"].first["alg"]).to eq("RS256")
  end

  it "exchanges credentials for tokens and userinfo" do
    post "/oauth/token", params: { grant_type: "password", username: user.email, password: "Sup3rSecret!Pass" }
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["access_token"]).to be_present

    get "/oauth/userinfo", headers: { "Authorization" => "Bearer #{body['access_token']}" }
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["sub"]).to eq(user.id)
  end
end
