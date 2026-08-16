require "rails_helper"

RSpec.describe Federation::SignatureVerifier, type: :service do
  let(:key) { OpenSSL::PKey::RSA.new(2048) }
  let(:actor) { create(:federation_actor, public_key_pem: key.public_key.to_pem) }

  # Builds a request double whose Signature header signs the given header set.
  def signed_request(headers:, date: Time.current.httpdate, host: "adun.unifed.ng", path: "/inbox")
    signed_string = "(request-target): post #{path}\n" +
      headers.reject { |h| h == "(request-target)" }.map { |h| "#{h}: #{send(h, host, date)}" }.join("\n")
    sig = Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, signed_string))
    hdr = %(keyId="#{actor.actor_uri}#main-key",algorithm="rsa-sha256",headers="#{headers.join(" ")}",signature="#{sig}")
    req = Object.new
    def req.headers; @h; end
    def req.request_method; "POST"; end
    def req.fullpath; @p; end
    req.instance_variable_set(:@h, { "Signature" => hdr, "host" => host, "date" => date })
    req.instance_variable_set(:@p, path)
    req
  end

  def host(_h, _d); "adun.unifed.ng"; end
  def date(_h, d); d; end

  it "accepts a signature covering (request-target) host date" do
    req = signed_request(headers: %w[(request-target) host date])
    expect(described_class.verify(request: req, actor_uri: actor.actor_uri)).to be(true)
  end

  it "rejects a signature with host stripped from the signed set (vuln-0003)" do
    req = signed_request(headers: %w[(request-target) date])
    expect(described_class.verify(request: req, actor_uri: actor.actor_uri)).to be(false)
  end

  it "rejects a signature with date stripped from the signed set (vuln-0003)" do
    req = signed_request(headers: %w[(request-target) host])
    expect(described_class.verify(request: req, actor_uri: actor.actor_uri)).to be(false)
  end

  it "rejects a signature with no headers parameter at all" do
    req = Object.new
    def req.headers; @h; end
    def req.request_method; "POST"; end
    def req.fullpath; "/inbox"; end
    hdr = %(keyId="#{actor.actor_uri}#main-key",algorithm="rsa-sha256",signature="x")
    req.instance_variable_set(:@h, { "Signature" => hdr, "host" => "adun.unifed.ng", "date" => Time.current.httpdate })
    expect(described_class.verify(request: req, actor_uri: actor.actor_uri)).to be(false)
  end

  it "rejects a request whose date is outside the ±5 minute skew window" do
    old = (Time.current - 600).httpdate # 10 minutes ago
    req = signed_request(headers: %w[(request-target) host date], date: old)
    expect(described_class.verify(request: req, actor_uri: actor.actor_uri)).to be(false)
  end

  it "rejects a malformed date header" do
    req = signed_request(headers: %w[(request-target) host date], date: "not-a-real-date")
    expect(described_class.verify(request: req, actor_uri: actor.actor_uri)).to be(false)
  end
end
