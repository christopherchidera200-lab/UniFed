require "rails_helper"

RSpec.describe "Administration API", type: :request do
  let(:university) { create(:university) }
  before { UniFed::Application.config.x.node_university_id = university.id }

  def token_for(user, roles: [])
    session = Identity::Session.create!(
      user: user, jti: SecureRandom.hex(16), refresh_jti: SecureRandom.hex(16),
      expired_at: 30.days.from_now
    )
    Identity::TokenService.issue_access(user: user, session: session, roles: roles)
  end

  def admin_user
    u = create(:identity_user, university: university, actor_type: "admin")
    role = Identity::Role.find_or_create_by!(name: "admin", university_id: university.id)
    role.update!(permissions: ["admin:users", "admin:results", "admin:moderation", "admin:announcements"])
    Identity::RoleAssignment.find_or_create_by!(user: u, role: role)
    u
  end

  def student_user
    s = create(:student, university: university)
    u = create(:identity_user, university: university, actor_type: "student", actor_id: s.id)
    s.update!(identity_subject: u.id)
    role = Identity::Role.find_or_create_by!(name: "student", university_id: university.id)
    role.update!(permissions: ["academic:read"])
    Identity::RoleAssignment.find_or_create_by!(user: u, role: role)
    u
  end

  describe "user directory (RBAC)" do
    it "lets an admin list users" do
      create(:identity_user, university: university, email: "prof@adun.edu.ng")
      get "/api/v1/admin/users", headers: { "Authorization" => "Bearer #{token_for(admin_user)}" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["users"].size).to be >= 1
    end

    it "forbids a student from listing users" do
      get "/api/v1/admin/users", headers: { "Authorization" => "Bearer #{token_for(student_user)}" }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without a token" do
      get "/api/v1/admin/users"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "node stats" do
    it "lets an admin view stats" do
      get "/api/v1/admin/stats", headers: { "Authorization" => "Bearer #{token_for(admin_user)}" }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to have_key("users")
      expect(body).to have_key("roles")
    end
  end

  describe "role assignment" do
    it "lets an admin assign a role to a user" do
      target = create(:identity_user, university: university)
      Identity::Role.find_or_create_by!(name: "staff", university_id: university.id)
        .update!(permissions: ["academic:write"])
      post "/api/v1/admin/users/#{target.id}/roles",
           params: { role: "staff" },
           headers: { "Authorization" => "Bearer #{token_for(admin_user)}" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["ok"]).to be_truthy
    end

    it "forbids a student from assigning roles" do
      target = create(:identity_user, university: university)
      post "/api/v1/admin/users/#{target.id}/roles",
           params: { role: "staff" },
           headers: { "Authorization" => "Bearer #{token_for(student_user)}" }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
