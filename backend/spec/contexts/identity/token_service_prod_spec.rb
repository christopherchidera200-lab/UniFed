require "rails_helper"

RSpec.describe Identity::TokenService, type: :service do
  describe ".secret production fail-closed (vuln-0004)" do
    let(:rsa_key) { "some-rsa-pem-value-000000000000000000000000000000000000000000000000" }

    def with_env(env)
      stub_const("ENV", ENV.to_hash.merge(env))
      yield
    end

    it "raises in production when TOKEN_SERVICE_SECRET is absent" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      with_env("TOKEN_SERVICE_SECRET" => nil, "OIDC_JWKS_PRIVATE" => rsa_key) do
        expect { Identity::TokenService.secret }
          .to raise_error(/TOKEN_SERVICE_SECRET must be set in production/)
      end
    end

    it "raises in production when TOKEN_SERVICE_SECRET EQUALS OIDC_JWKS_PRIVATE (same-value confusion)" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      with_env("TOKEN_SERVICE_SECRET" => rsa_key, "OIDC_JWKS_PRIVATE" => rsa_key) do
        expect { Identity::TokenService.secret }
          .to raise_error(/distinct from OIDC_JWKS_PRIVATE/)
      end
    end

    it "uses TOKEN_SERVICE_SECRET when present and distinct (even in production)" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      hmac = "distinct-hmac-secret-1234567890abcdef"
      with_env("TOKEN_SERVICE_SECRET" => hmac, "OIDC_JWKS_PRIVATE" => rsa_key) do
        expect(Identity::TokenService.secret).to eq(hmac)
      end
    end
  end
end
