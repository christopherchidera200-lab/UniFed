module Federation
  # Verifies an HTTP Signature (draft-cavage) on an incoming AP request using the
  # sender's public key (resolved via the actor document / Webfinger).
  class SignatureVerifier
    # Returns true if the signature over (method, path, digest, date) is valid.
    def self.verify(request:, actor_uri:)
      sig_header = request.headers["Signature"].to_s
      return false if sig_header.blank?

      params = parse_sig_header(sig_header)
      return false unless params["keyId"] && params["signature"]

      key_id = params["keyId"]
      # keyId typically "https://host/actors/x#main-key" -> actor_uri is prefix.
      actor = Federation::Actor.find_by(actor_uri: key_id.gsub(/#main-key\z/, ""))
      actor ||= WebfingerService.resolve(key_id)
      return false unless actor&.public_key_pem

      pub = OpenSSL::PKey::RSA.new(actor.public_key_pem)
      signed_string = build_signed_string(request, params["headers"])
      begin
        pub.verify(OpenSSL::Digest::SHA256.new, Base64.strict_decode64(params["signature"]), signed_string)
      rescue OpenSSL::PKey::RSAError, ArgumentError
        false
      end
    end

    def self.parse_sig_header(header)
      # keyId="...",algorithm="rsa-sha256",headers="(request-target) host date digest",signature="..."
      header.scan(/(\w+)="([^"]*)"/).to_h
    end

    def self.build_signed_string(request, headers)
      headers.to_s.split(/\s+/).map do |h|
        case h
        when "(request-target)"
          "(request-target): #{request.request_method.downcase} #{request.fullpath}"
        else
          "#{h}: #{request.headers[h]}"
        end
      end.join("\n")
    end
  end
end
