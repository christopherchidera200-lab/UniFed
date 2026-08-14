require "rails_helper"

RSpec.describe "API auth gating (public vs protected)", type: :request do
  let(:university) { create(:university) }
  before { UniFed::Application.config.x.node_university_id = university.id }

  # ---- PUBLIC browse endpoints (no token required) ----
  it "catalog courses are publicly accessible" do
    create(:course, programme: create(:programme, department: create(:department, faculty: create(:faculty, university: university))))
    get "/api/v1/catalog/courses"
    expect(response).to have_http_status(:ok)
  end

  it "library resources are publicly accessible" do
    create(:library_resource, university: university)
    get "/api/v1/library/resources"
    expect(response).to have_http_status(:ok)
  end

  it "calendar events are publicly accessible" do
    get "/api/v1/calendar/events"
    expect(response).to have_http_status(:ok)
  end

  it "career opportunities are publicly accessible" do
    get "/api/v1/career/opportunities"
    expect(response).to have_http_status(:ok)
  end

  # ---- PROTECTED endpoints (token required) ----
  it "profile is rejected without auth" do
    get "/api/v1/profile"
    expect(response).to have_http_status(:unauthorized)
  end

  it "academic records are rejected without auth" do
    get "/api/v1/academic/00000000-0000-0000-0000-000000000000/students/00000000-0000-0000-0000-000000000000/records"
    expect(response).to have_http_status(:unauthorized)
  end

  it "feed post creation is rejected without auth" do
    post "/api/v1/feed/posts", params: { text: "hi" }.to_json, headers: { "Content-Type" => "application/json" }
    expect(response).to have_http_status(:unauthorized)
  end

  context "authenticated caller" do
    let(:user) do
      u = create(:identity_user, university: university, password: "Passw0rd!")
      Identity::Role.find_or_create_by!(university_id: university.id, name: "member")
      u
    end
    let(:token) do
      session = Identity::Session.create!(
        user: user, jti: SecureRandom.hex(16), refresh_jti: SecureRandom.hex(16),
        expired_at: 30.days.from_now
      )
      Identity::TokenService.issue_access(user: user, session: session, roles: user.roles.pluck(:name))
    end

    it "profile returns the authenticated user's own data (not another user's)" do
      get "/api/v1/profile", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["email"]).to eq(user.email)
      expect(body["display_name"]).to eq(user.display_name)
    end

    it "profile does not expose password material" do
      get "/api/v1/profile", headers: { "Authorization" => "Bearer #{token}" }
      body = JSON.parse(response.body)
      expect(body).not_to have_key("password")
      expect(body).not_to have_key("secret_enc")
      expect(body).not_to have_key("credentials")
    end
  end
end
