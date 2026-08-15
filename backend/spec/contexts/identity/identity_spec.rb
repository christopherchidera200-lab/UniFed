require "rails_helper"

RSpec.describe Identity::User, type: :model do
  let(:university) { create(:university) }

  it "is valid with valid attributes" do
    user = build(:identity_user, university: university)
    expect(user).to be_valid
  end

  it "enforces unique email per university" do
    create(:identity_user, university: university, email: "same@adun.edu.ng")
    dup = build(:identity_user, university: university, email: "same@adun.edu.ng")
    expect(dup).not_to be_valid
  end

  it "computes permission set from assigned roles" do
    user = create(:identity_user, university: university, skip_password: true)
    Identity::RoleService.seed_baseline_roles(university)
    Identity::RoleService.assign(user: user, role_name: "staff")
    expect(user.reload.has_permission?("student_id:issue")).to be true
    expect(user.reload.has_permission?("admin:users")).to be false
  end

  it "reports mfa_enrolled? from confirmed devices" do
    user = create(:identity_user, university: university)
    expect(user.mfa_enrolled?).to be false
    create(:identity_mfa_device, user: user, confirmed: true)
    expect(user.reload.mfa_enrolled?).to be true
  end
end

RSpec.describe Identity::Credential, type: :model do
  let(:user) { create(:identity_user) }

  it "verifies a correct password and rejects a wrong one" do
    user = create(:identity_user, skip_password: true)
    cred = create(:identity_credential, user: user,
                  kind: "password", secret_enc: Identity::Credential.hash_password("hunter2!!"))
    expect(cred.verify_password("hunter2!!")).to be true
    expect(cred.verify_password("wrong")).to be false
  end
end

RSpec.describe Identity::RoleAssignment, type: :model do
  it "assigns and revokes roles via RoleService" do
    university = create(:university)
    user = create(:identity_user, university: university)
    Identity::RoleService.seed_baseline_roles(university)
    Identity::RoleService.assign(user: user, role_name: "staff")
    expect(user.reload.has_permission?("student_id:issue")).to be true
    Identity::RoleService.revoke(user: user, role_name: "staff")
    expect(user.reload.has_permission?("student_id:issue")).to be false
  end
end

RSpec.describe Identity::ConsentRecord, type: :model do
  it "withdraws consent (NDPA)" do
    rec = create(:identity_consent_record, purpose: "health_wellbeing", granted: true)
    expect(rec.withdrawn?).to be false
    rec.withdraw!
    expect(rec.reload.withdrawn?).to be true
  end
end

RSpec.describe Identity::TokenService, type: :service do
  let(:user) { create(:identity_user) }
  let(:session) { create(:identity_session, user: user) }

  it "round-trips an access token and rejects a tampered one" do
    token = Identity::TokenService.issue_access(user: user, session: session, roles: ["student"])
    payload = Identity::TokenService.verify(token, type: "access")
    expect(payload["sub"]).to eq(user.id.to_s)
    expect(payload["roles"]).to eq(["student"])

    bad = token[0...-3] + "xxx"
    expect(Identity::TokenService.verify(bad, type: "access")).to be_nil
  end

  it "rejects a refresh token when verified as access type" do
    refresh = Identity::TokenService.issue_refresh(user: user, session: session)
    expect(Identity::TokenService.verify(refresh, type: "access")).to be_nil
  end

  # F-02: tokens MUST be bound to the configured audience.
  it "embeds the configured audience in issued tokens" do
    token = Identity::TokenService.issue_access(user: user, session: session, roles: ["student"])
    decoded, = JWT.decode(token, Identity::TokenService.send(:secret), true, algorithm: Identity::TokenService::ALGO)
    expect(decoded["aud"]).to eq(Identity::TokenService.audience)
  end

  it "rejects a token whose audience does not match (F-02)" do
    token = Identity::TokenService.issue_access(user: user, session: session, roles: ["student"])
    decoded, = JWT.decode(token, Identity::TokenService.send(:secret), true, algorithm: Identity::TokenService::ALGO)
    wrong = JWT.encode(decoded.merge("aud" => "https://evil.example.com"),
                       Identity::TokenService.send(:secret), Identity::TokenService::ALGO)
    expect(Identity::TokenService.verify(wrong, type: "access")).to be_nil
  end

  it "rejects a token with no audience claim (F-02)" do
    token = Identity::TokenService.issue_access(user: user, session: session, roles: ["student"])
    decoded, = JWT.decode(token, Identity::TokenService.send(:secret), true, algorithm: Identity::TokenService::ALGO)
    no_aud = JWT.encode(decoded.except("aud"),
                        Identity::TokenService.send(:secret), Identity::TokenService::ALGO)
    expect(Identity::TokenService.verify(no_aud, type: "access")).to be_nil
  end
end

RSpec.describe Identity::PasswordAuthService, type: :service do
  let(:university) { create(:university) }

  it "authenticates a valid password and issues tokens (no MFA)" do
    user = create(:identity_user, university: university, password: "Sup3rSecret!")
    result = Identity::PasswordAuthService.authenticate(
      email: user.email, password: "Sup3rSecret!", university: university,
      ip: "127.0.0.1", user_agent: "rspec")
    expect(result.ok?).to be true
    expect(result.mfa_required?).to be false
    expect(result.tokens[:access_token]).to be_present
    expect(result.tokens[:refresh_token]).to be_present
  end

  it "rejects a wrong password" do
    user = create(:identity_user, university: university, password: "Sup3rSecret!")
    result = Identity::PasswordAuthService.authenticate(
      email: user.email, password: "nope", university: university,
      ip: "127.0.0.1", user_agent: "rspec")
    expect(result.ok?).to be false
    expect(result.reason).to eq(:invalid_credentials)
  end

  it "requires MFA step-up when a device is enrolled" do
    user = create(:identity_user, university: university, password: "Sup3rSecret!")
    create(:identity_mfa_device, user: user, confirmed: true)
    result = Identity::PasswordAuthService.authenticate(
      email: user.email, password: "Sup3rSecret!", university: university,
      ip: "127.0.0.1", user_agent: "rspec")
    expect(result.ok?).to be true
    expect(result.mfa_required?).to be true
    expect(result.pre_auth).to be_present
  end
end

RSpec.describe Identity::MfaService, type: :service do
  let(:user) { create(:identity_user) }

  it "enrolls and confirms a TOTP device" do
    out = Identity::MfaService.begin_totp(user, label: "Authy")
    expect(out[:device_id]).to be_present
    code = ROTP::TOTP.new(out[:secret], issuer: "UniFed").now
    expect(Identity::MfaService.confirm_totp(user, out[:device_id], code)).to be true
    expect(user.reload.mfa_enrolled?).to be true
  end
end
