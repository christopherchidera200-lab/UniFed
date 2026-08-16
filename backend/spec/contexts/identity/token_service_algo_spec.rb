require "rails_helper"
require "jwt"

RSpec.describe Identity::TokenService, type: :service do
  let(:user) { create(:identity_user) }
  let(:session) { create(:identity_session, user: user) }

  it "round-trips an RS256 access token and rejects a tampered one" do
    token = described_class.issue_access(user: user, session: session, roles: ["student"])
    payload = described_class.verify(token, type: "access")
    expect(payload).to be_present
    expect(payload["sub"]).to eq(user.id.to_s)
    expect(payload["roles"]).to eq(["student"])

    bad = token[0...-3] + "xxx"
    expect(described_class.verify(bad, type: "access")).to be_nil
  end

  it "rejects a refresh token when verified as access type" do
    refresh = described_class.issue_refresh(user: user, session: session)
    expect(described_class.verify(refresh, type: "access")).to be_nil
  end

  # vuln-0004 regression: a token forged with HS256 using the published public
  # key (or any HMAC secret) must NOT be accepted by the RS256 verifier.
  it "rejects an HS256-signed token (algorithm confusion) even if signed with the public key" do
    pub_pem = Identity::OidcKeyService.public_key.to_pem
    forged = JWT.encode(
      { sub: user.id.to_s, iss: described_class.issuer, aud: described_class.audience,
        typ: "access", iat: Time.current.to_i, exp: (Time.current + 15.minutes).to_i,
        jti: "forged" },
      pub_pem, "HS256"
    )
    expect(described_class.verify(forged, type: "access")).to be_nil
  end

  it "rejects an RS256 token whose aud does not match" do
    token = JWT.encode(
      { sub: user.id.to_s, iss: described_class.issuer, aud: "wrong-audience",
        typ: "access", iat: Time.current.to_i, exp: (Time.current + 15.minutes).to_i,
        jti: "x" },
      Identity::OidcKeyService.private_key, "RS256"
    )
    expect(described_class.verify(token, type: "access")).to be_nil
  end
end
