require "rails_helper"

RSpec.describe "Auth registration (POST /api/v1/auth/register)", type: :request do
  let(:university) { create(:university) }
  before { UniFed::Application.config.x.node_university_id = university.id }

  def register(params)
    post "/api/v1/auth/register", params: params, as: :json
  end

  it "creates a user with Argon2 password and returns tokens (auto-login)" do
    expect {
      register(name: "Chidera Chris", email: "chidera@adun.edu.ng", password: "Passw0rd!")
    }.to change(Identity::User, :count).by(1)

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body["access_token"]).to be_present
    expect(body["refresh_token"]).to be_present
    expect(body).not_to have_key("password")
    expect(body).not_to have_key("secret_enc")

    user = Identity::User.find_by(email: "chidera@adun.edu.ng")
    expect(user).to be_present
    expect(user.credentials.where(kind: "password").first.verify_password("Passw0rd!")).to be true
  end

  it "assigns only a base 'member' role (never admin) by default" do
    register(name: "Base", email: "base@adun.edu.ng", password: "Passw0rd!")
    user = Identity::User.find_by(email: "base@adun.edu.ng")
    expect(user.admin?).to be false
    expect(user.roles.map(&:name)).to include("member")
    expect(user.roles.map(&:name)).not_to include("admin")
  end

  it "rejects a duplicate email with 409 conflict" do
    create(:identity_user, university: university, email: "dup@adun.edu.ng", skip_password: true)
    register(name: "X", email: "dup@adun.edu.ng", password: "Passw0rd!")
    expect(response).to have_http_status(:conflict)
    expect(JSON.parse(response.body)["error"]).to eq("email_taken")
  end

  it "rejects a weak password" do
    register(name: "X", email: "weak@adun.edu.ng", password: "password")
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to eq("password_too_weak")
  end

  it "rejects a missing email" do
    register(name: "X", password: "Passw0rd!")
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "prevents privilege escalation via client-supplied role/actor_type" do
    register(name: "Evil", email: "evil@adun.edu.ng", password: "Passw0rd!", role: "admin", actor_type: "admin")
    user = Identity::User.find_by(email: "evil@adun.edu.ng")
    expect(user.admin?).to be false
    expect(user.roles.map(&:name)).not_to include("admin")
  end

  it "links a student record when a valid, unclaimed matric number is supplied" do
    matric = "ADUN/FS/CYB/23/001"
    register(name: "Matric User", email: "matric@adun.edu.ng", password: "Passw0rd!", matric_no: matric)
    user = Identity::User.find_by(email: "matric@adun.edu.ng")
    expect(Academic::Student.find_by(matric_no: matric, identity_subject: user.id)).to be_present
    expect(user.roles.map(&:name)).to include("student")
  end

  it "fails when the node university is not configured" do
    UniFed::Application.config.x.node_university_id = nil
    register(name: "X", email: "x@adun.edu.ng", password: "Passw0rd!")
    expect(response).to have_http_status(:service_unavailable)
    expect(JSON.parse(response.body)["error"]).to eq("node_not_configured")
  end

  it "does not log the password" do
    # RegistrationService does not write the plaintext password to audit meta.
    expect(Identity::AuditService).not_to receive(:log!).with(hash_including(meta: hash_including(password: anything)))
    register(name: "Log", email: "log@adun.edu.ng", password: "Passw0rd!")
  end
end
