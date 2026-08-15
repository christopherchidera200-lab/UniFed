require "rails_helper"

RSpec.describe "Assignments / LMS API", type: :request do
  let(:university) { create(:university) }
  before { UniFed::Application.config.x.node_university_id = university.id }

  def token_for(user, roles: [])
    session = Identity::Session.create!(
      user: user, jti: SecureRandom.hex(16), refresh_jti: SecureRandom.hex(16),
      expired_at: 30.days.from_now
    )
    Identity::TokenService.issue_access(user: user, session: session, roles: roles)
  end

  # lecturer user with academic:write
  let(:lecturer) { create(:lecturer, university: university) }
  let(:lecturer_user) do
    u = create(:identity_user, university: university, actor_type: "staff", actor_id: lecturer.id)
    role = Identity::Role.find_or_create_by!(name: "staff", university_id: university.id)
    role.update!(permissions: ["academic:write", "campus:manage"])
    Identity::RoleAssignment.find_or_create_by!(user: u, role: role)
    u
  end

  # student user linked to a Student record enrolled in the offering's programme
  let(:offering) { create(:course_offering, lecturer: lecturer) }
  let(:student) { create(:student, university: university) }
  let(:student_user) do
    student.student_enrollments.create!(programme: offering.course.programme, academic_session: offering.academic_session)
    u = create(:identity_user, university: university, actor_type: "student", actor_id: student.id)
    student.update!(identity_subject: u.id)
    role = Identity::Role.find_or_create_by!(name: "student", university_id: university.id)
    role.update!(permissions: ["academic:read"])
    Identity::RoleAssignment.find_or_create_by!(user: u, role: role)
    u
  end

  let(:other_lecturer) { create(:lecturer, university: university) }

  describe "lecturer workflow" do
    it "creates an assignment for an offering they teach" do
      post "/api/v1/assignments",
           params: { assignment: { course_offering_id: offering.id, title: "Essay 1", published: true } },
           headers: { "Authorization" => "Bearer #{token_for(lecturer_user)}" }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["title"]).to eq("Essay 1")
    end

    it "forbids a student from creating an assignment" do
      post "/api/v1/assignments",
           params: { assignment: { course_offering_id: offering.id, title: "X" } },
           headers: { "Authorization" => "Bearer #{token_for(student_user)}" }
      expect(response).to have_http_status(:forbidden)
    end

    it "grades a submission (lecturer only)" do
      assignment = create(:lms_assignment, course_offering: offering, lecturer: lecturer)
      sub = create(:lms_submission, assignment: assignment, student: student)
      patch "/api/v1/assignments/#{assignment.id}/submissions/#{sub.id}",
            params: { score: 85, feedback: "good" },
            headers: { "Authorization" => "Bearer #{token_for(lecturer_user)}" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["score"].to_i).to eq(85)
      expect(sub.reload.status).to eq("graded")
    end

    it "forbids another lecturer from grading" do
      assignment = create(:lms_assignment, course_offering: offering, lecturer: lecturer)
      sub = create(:lms_submission, assignment: assignment, student: student)
      patch "/api/v1/assignments/#{assignment.id}/submissions/#{sub.id}",
            params: { score: 85 },
            headers: { "Authorization" => "Bearer #{token_for(other_lecturer_user)}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "student workflow" do
    it "submits to a published assignment" do
      assignment = create(:lms_assignment, course_offering: offering, lecturer: lecturer, published: true)
      post "/api/v1/assignments/#{assignment.id}/submit",
           params: { body: "my answer" },
           headers: { "Authorization" => "Bearer #{token_for(student_user)}" }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["status"]).to eq("submitted")
    end

    it "returns 401 without a token" do
      get "/api/v1/assignments"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # helper for the other-lecturer token
  let(:other_lecturer_user) do
    u = create(:identity_user, university: university, actor_type: "staff", actor_id: other_lecturer.id)
    role = Identity::Role.find_or_create_by!(name: "staff2", university_id: university.id)
    role.update!(permissions: ["academic:write"])
    Identity::RoleAssignment.find_or_create_by!(user: u, role: role)
    u
  end
end
