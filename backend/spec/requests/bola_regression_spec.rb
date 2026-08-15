require "rails_helper"

RSpec.describe "Authorization / BOLA regression (F-09, F-10)", type: :request do
  let(:university) { create(:university) }
  before { UniFed::Application.config.x.node_university_id = university.id }

  def token_for(user)
    session = Identity::Session.create!(
      user: user, jti: SecureRandom.hex(16), refresh_jti: SecureRandom.hex(16),
      expired_at: 30.days.from_now
    )
    Identity::TokenService.issue_access(user: user, session: session, roles: user.roles.pluck(:name))
  end

  # A user whose Account is linked to a Student record (so current_student resolves).
  def linked_user
    u = create(:identity_user, university: university, password: "Passw0rd!")
    s = create(:student, university: university, identity_subject: u.id)
    [u, s]
  end

  context "F-09 — notifications#read ownership" do
    it "rejects marking another user's notification read (404, not silently applied)" do
      victim = create(:identity_user, university: university)
      attacker = create(:identity_user, university: university)
      note = Notification::NotificationService.notify!(
        university: university, user: victim, category: "system", title: "secret"
      )

      post "/api/v1/notifications/#{note.id}/read",
           headers: { "Authorization" => "Bearer #{token_for(attacker)}" }

      expect(response).to have_http_status(:not_found)
      expect(note.reload.status).to eq("unread")
    end

    it "allows marking your own notification read" do
      owner = create(:identity_user, university: university)
      note = Notification::NotificationService.notify!(
        university: university, user: owner, category: "system", title: "mine"
      )

      post "/api/v1/notifications/#{note.id}/read",
           headers: { "Authorization" => "Bearer #{token_for(owner)}" }

      expect(response).to have_http_status(:ok)
      expect(note.reload.status).to eq("read")
    end
  end

  context "F-10 — library#return_resource ownership" do
    it "rejects returning another user's loan (404)" do
      _, victim_student = linked_user
      attacker_user, _ = linked_user
      resource = create(:library_resource, university: university)
      loan = create(:library_loan, student: victim_student, library_resource: resource, status: "borrowed")

      post "/api/v1/library/return", params: { loan_id: loan.id }.to_json,
           headers: { "Content-Type" => "application/json", "Authorization" => "Bearer #{token_for(attacker_user)}" }

      expect(response).to have_http_status(:not_found)
      expect(loan.reload.status).to eq("borrowed")
    end

    it "allows returning your own loan" do
      owner_user, owner_student = linked_user
      resource = create(:library_resource, university: university)
      loan = create(:library_loan, student: owner_student, library_resource: resource, status: "borrowed")

      post "/api/v1/library/return", params: { loan_id: loan.id }.to_json,
           headers: { "Content-Type" => "application/json", "Authorization" => "Bearer #{token_for(owner_user)}" }

      expect(response).to have_http_status(:ok)
      expect(loan.reload.status).to eq("returned")
    end
  end
end
