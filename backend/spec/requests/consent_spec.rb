require "rails_helper"

RSpec.describe "Consent API", type: :request do
  let(:university) { create(:university) }
  before { UniFed::Application.config.x.node_university_id = university.id }

  def token_for(user, roles: [])
    session = Identity::Session.create!(
      user: user, jti: SecureRandom.hex(16), refresh_jti: SecureRandom.hex(16),
      expired_at: 30.days.from_now
    )
    Identity::TokenService.issue_access(user: user, session: session, roles: roles)
  end

  def user
    @user ||= create(:identity_user, university: university, actor_type: "student")
  end

  def auth
    { "Authorization" => "Bearer #{token_for(user)}" }
  end

  describe "POST /api/v1/consent" do
    it "records a consent grant for a new purpose with default policy version and timestamp (NDPA lawful basis)" do
      post "/api/v1/consent", params: { purpose: "health_wellbeing", granted: true }, headers: auth
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["ok"]).to be true
      expect(body["granted"]).to be true
      expect(body["withdrawn"]).to be false
      expect(body["version"]).to eq("1.0")
      expect(body["granted_at"]).to be_present
      rec = user.reload.consent_records.find_by(purpose: "health_wellbeing")
      expect(rec).to be_present
      expect(rec.granted).to be true
      expect(rec.consent_version).to eq("1.0")
      expect(rec.granted_at).to be_present
      expect(rec.withdrawn_at).to be_nil
    end

    it "stores an explicit consent policy version when supplied" do
      post "/api/v1/consent", params: { purpose: "career", granted: true, version: "2.1" }, headers: auth
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["version"]).to eq("2.1")
      expect(user.reload.consent_records.find_by(purpose: "career").consent_version).to eq("2.1")
    end

    it "withdraws consent when granted is false" do
      create(:identity_consent_record, user: user, purpose: "health_wellbeing", granted: true)
      post "/api/v1/consent", params: { purpose: "health_wellbeing", granted: false }, headers: auth
      expect(response).to have_http_status(:ok)
      rec = user.reload.consent_records.find_by(purpose: "health_wellbeing")
      expect(rec.granted).to be false
      expect(rec.withdrawn?).to be true
      expect(rec.granted_at).to be_nil
    end

    it "re-grants a previously withdrawn purpose and refreshes granted_at" do
      create(:identity_consent_record, user: user, purpose: "career", granted: false,
             withdrawn_at: Time.current, granted_at: 1.day.ago)
      post "/api/v1/consent", params: { purpose: "career", granted: true }, headers: auth
      expect(response).to have_http_status(:ok)
      rec = user.reload.consent_records.find_by(purpose: "career")
      expect(rec.granted).to be true
      expect(rec.withdrawn?).to be false
      expect(rec.granted_at).to be > 1.hour.ago
    end

    it "requires a purpose" do
      post "/api/v1/consent", params: { granted: true }, headers: auth
      expect(response).to have_http_status(:bad_request)
    end

    it "rejects an unauthenticated request" do
      post "/api/v1/consent", params: { purpose: "career", granted: true }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/consent" do
    it "lists the current user's consent ledger with version and grant timestamp" do
      create(:identity_consent_record, user: user, purpose: "health_wellbeing", granted: true)
      get "/api/v1/consent", headers: auth
      expect(response).to have_http_status(:ok)
      rec = JSON.parse(response.body).find { |r| r["purpose"] == "health_wellbeing" }
      expect(rec).to be_present
      expect(rec["consent_version"]).to eq("1.0")
      expect(rec["granted_at"]).to be_present
    end
  end
end
