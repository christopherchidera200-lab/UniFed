module Identity
  # OIDC asymmetric signing keys (RS256) for the node's JWKS. In production the
  # private key is supplied via ENV[OIDC_JWKS_PRIVATE] (PEM or base64 PEM) and
  # stored in KMS; in dev/test an ephemeral key is generated per boot.
  class OidcKeyService
    KID = ENV.fetch("OIDC_KID", "unifed-rs256-1")

    class << self
      def private_key
        @private_key ||= load_or_generate
      end

      def public_key
        private_key.public_key
      end

      # JWK (RFC 7517) for the public key, used in /.well-known/jwks.json
      def jwk
        p = public_key
        {
          kty: "RSA",
          alg: "RS256",
          use: "sig",
          kid: KID,
          n: jwk_int(p.n),
          e: jwk_int(p.e)
        }
      end

      private

      def jwk_int(int)
        # Big-endian, base64url, no padding. Hex of the integer, left-padded to
        # an even length (each byte = 2 hex chars).
        hex = int.to_s(16)
        hex = "0" + hex if hex.length.odd?
        [hex].pack("H*").then { |b| Base64.urlsafe_encode64(b) }.gsub("=", "")
      end

      def load_or_generate
        raw = ENV["OIDC_JWKS_PRIVATE"].presence
        return OpenSSL::PKey::RSA.new(raw) if raw && raw.include?("BEGIN")
        if raw
          begin
            return OpenSSL::PKey::RSA.new(Base64.strict_decode64(raw))
          rescue ArgumentError, OpenSSL::PKey::RSAError
            nil
          end
        end
        OpenSSL::PKey::RSA.new(2048)
      end
    end
  end
end
