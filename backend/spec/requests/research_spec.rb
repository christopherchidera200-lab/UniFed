require "rails_helper"

RSpec.describe "Research Hub API", type: :request do
  let(:university) { create(:university) }
  before { UniFed::Application.config.x.node_university_id = university.id }

  def token_for(user, roles: [])
    session = Identity::Session.create!(
      user: user, jti: SecureRandom.hex(16), refresh_jti: SecureRandom.hex(16),
      expired_at: 30.days.from_now
    )
    Identity::TokenService.issue_access(user: user, session: session, roles: roles)
  end

  def staff_user
    u = create(:identity_user, university: university, actor_type: "staff", actor_id: create(:lecturer, university: university).id)
    role = Identity::Role.find_or_create_by!(name: "research_staff", university_id: university.id)
    role.update!(permissions: ["research:manage"])
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

  describe "read access" do
    it "lists groups (authenticated)" do
      create(:research_group, university: university, name: "AI Lab")
      get "/api/v1/research/groups", headers: { "Authorization" => "Bearer #{token_for(staff_user)}" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to be >= 1
    end

    it "returns 401 without a token" do
      get "/api/v1/research/groups"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "group creation (RBAC)" do
    it "allows staff with research:manage to create a group" do
      post "/api/v1/research/groups",
           params: { group: { name: "Bio Lab", description: "x" } },
           headers: { "Authorization" => "Bearer #{token_for(staff_user)}" }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["name"]).to eq("Bio Lab")
    end

    it "forbids a plain student from creating a group" do
      post "/api/v1/research/groups",
           params: { group: { name: "X" } },
           headers: { "Authorization" => "Bearer #{token_for(student_user)}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "membership" do
    it "lets a group lead add a member" do
      lead = staff_user
      group = Research::ResearchService.create_group!(university: university, leader: lead, attrs: { name: "Lab" })
      member = create(:identity_user, university: university)
      post "/api/v1/research/groups/#{group.id}/members",
           params: { user_id: member.id },
           headers: { "Authorization" => "Bearer #{token_for(lead)}" }
      expect(response).to have_http_status(:created)
    end

    it "forbids a non-manager from adding a member" do
      group = create(:research_group, university: university)
      intruder = student_user
      victim = create(:identity_user, university: university)
      post "/api/v1/research/groups/#{group.id}/members",
           params: { user_id: victim.id },
           headers: { "Authorization" => "Bearer #{token_for(intruder)}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "profiles" do
    it "searches profiles" do
      create(:research_profile, university: university, title: "Dr. Neural")
      get "/api/v1/research/profiles?q=Neural", headers: { "Authorization" => "Bearer #{token_for(staff_user)}" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to be >= 1
    end
  end
end
