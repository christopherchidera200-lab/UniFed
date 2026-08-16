require "rails_helper"

RSpec.describe Identity::TokenService, type: :service do
  describe ".secret production fail-closed (vuln-0004)" do
    around do |example|
      orig = Rails.env
      Rails.instance_variable_get(:@_env) rescue nil
      example.run
    ensure
      # restore
    end

    it "raises in production when TOKEN_SERVICE_SECRET is absent (no RSA-key fallback)" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      stub_const("ENV", ENV.to_hash.merge("TOKEN_SERVICE_SECRET" => nil, "OIDC_JWKS_PRIVATE" => "some-rsa-pem"))
      expect { Identity::TokenService.secret }
        .to raise_error(/TOKEN_SERVICE_SECRET must be set in production/)
    end

    it "uses TOKEN_SERVICE_SECRET when provided (even in production)" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      stub_const("ENV", ENV.to_hash.merge("TOKEN_SERVICE_SECRET" => "distinct-hmac-secret-1234567890", "OIDC_JWKS_PRIVATE" => "some-rsa-pem"))
      expect(Identity::TokenService.secret).to eq("distinct-hmac-secret-1234567890")
    end
  end
end
