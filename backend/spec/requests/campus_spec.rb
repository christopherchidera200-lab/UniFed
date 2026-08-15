require "rails_helper"

RSpec.describe "Campus / Smart-Campus API", type: :request do
  let(:university) { create(:university) }
  before { UniFed::Application.config.x.node_university_id = university.id }

  def token_for(user)
    session = Identity::Session.create!(
      user: user, jti: SecureRandom.hex(16), refresh_jti: SecureRandom.hex(16),
      expired_at: 30.days.from_now
    )
    Identity::TokenService.issue_access(user: user, session: session, roles: user.roles.pluck(:name))
  end

  def auth(user)
    { "Authorization" => "Bearer #{token_for(user)}" }
  end

  let(:campus) { create(:campus_campus, university: university) }
  let(:student) { create(:identity_user, university: university) }

  def staff_user
    u = create(:identity_user, university: university)
    Identity::RoleService.seed_baseline_roles(university)
    Identity::RoleService.assign(user: u, role_name: "staff")
    u
  end

  it "lists places (authenticated, node-scoped)" do
    create(:campus_place, university: university, campus: campus, kind: "library", name: "Main")
    get "/api/v1/campus/places", headers: auth(student)
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).size).to eq(1)
  end

  it "returns 401 without a token" do
    get "/api/v1/campus/places"
    expect(response).to have_http_status(:unauthorized)
  end

  it "finds places near a coordinate" do
    create(:campus_place, university: university, campus: campus, lat: 6.5244, lng: 3.3792, name: "Near")
    create(:campus_place, university: university, campus: campus, lat: 6.9000, lng: 3.3792, name: "Far")
    get "/api/v1/campus/near?lat=6.5244&lng=3.3792&radius=5", headers: auth(student)
    expect(response).to have_http_status(:ok)
    names = JSON.parse(response.body).map { |p| p["name"] }
    expect(names).to include("Near")
    expect(names).not_to include("Far")
  end

  it "forbids creating a place without campus:manage permission" do
    post "/api/v1/campus/places",
         params: { place: { campus_id: campus.id, name: "X", kind: "library", lat: 6.5, lng: 3.3 } },
         headers: auth(student)
    expect(response).to have_http_status(:forbidden)
  end

  it "allows staff to create a place (RBAC)" do
    post "/api/v1/campus/places",
         params: { place: { campus_id: campus.id, name: "New Lab", kind: "laboratory", lat: 6.5, lng: 3.3 } },
         headers: auth(staff_user)
    expect(response).to have_http_status(:created)
    expect(JSON.parse(response.body)["name"]).to eq("New Lab")
  end

  it "does not leak places across universities" do
    other = create(:university)
    create(:campus_place, university: other, campus: create(:campus_campus, university: other), name: "Other")
    get "/api/v1/campus/places", headers: auth(student)
    expect(JSON.parse(response.body).map { |p| p["name"] }).not_to include("Other")
  end
end
