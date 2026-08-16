module Federation
  # Verifies an HTTP Signature (draft-cavage) on an incoming AP request.
  #
  # F-04 hardening:
  #  - resolves the signing key from a LOCAL actor first, then (if unknown)
  #    fetches the remote actor document over HTTPS and caches the public key;
  #  - enforces that the signature's keyId identifies the SAME actor claimed in
  #    the activity body, so a sender cannot sign with their own key while
  #    impersonating another actor.
  class SignatureVerifier
    CACHE_TTL = 1.hour

    # The signature MUST cover these headers; covering only (request-target)
    # (the vuln-0003 gap) is insufficient because it omits host/date, letting
    # an attacker replay or re-target a captured signature.
    REQUIRED_HEADERS = %w[host date].freeze

    def self.verify(request:, actor_uri:)
      sig_header = request.headers["Signature"].to_s
      return false if sig_header.blank?

      params = parse_sig_header(sig_header)
      return false unless params["keyId"] && params["signature"]
      return false unless params["headers"]

      signed = params["headers"].to_s.split(/\s+/)
      return false unless (REQUIRED_HEADERS - signed).empty?

      # The actor that signed must be the actor named in the activity.
      key_actor_uri = params["keyId"].gsub(/#main-key\z/, "")
      return false if actor_uri.present? && key_actor_uri != actor_uri.gsub(/#main-key\z/, "")

      # Reject stale / forged dates outside the allowed skew (vuln-0003).
      return false unless date_within_skew?(request.headers["date"].to_s)

      pub = public_key_for(key_actor_uri)
      return false unless pub

      signed_string = build_signed_string(request, signed)
      begin
        pub.verify(OpenSSL::Digest::SHA256.new, Base64.strict_decode64(params["signature"]), signed_string)
      rescue OpenSSL::PKey::RSAError, ArgumentError
        false
      end
    end

    # Accepts an HTTP-date only within ±5 minutes of now (vuln-0003). A missing
    # or malformed date is rejected.
    def self.date_within_skew?(date_header)
      return false if date_header.blank?
      time = Time.httpdate(date_header)
      (time - Time.current).abs <= 5.minutes
    rescue ArgumentError
      false
    end

    def self.public_key_for(actor_uri)
      actor = Federation::Actor.find_by(actor_uri: actor_uri)
      return OpenSSL::PKey::RSA.new(actor.public_key_pem) if actor&.public_key_pem

      # F-04: fetch remote actor document and extract the public key.
      cached = Rails.cache.read("federation:actor_key:#{actor_uri}")
      return OpenSSL::PKey::RSA.new(cached) if cached

      pem = fetch_remote_public_key(actor_uri)
      Rails.cache.write("federation:actor_key:#{actor_uri}", pem, expires_in: CACHE_TTL) if pem
      pem ? OpenSSL::PKey::RSA.new(pem) : nil
    rescue OpenSSL::PKey::RSAError
      nil
    end

    def self.fetch_remote_public_key(actor_uri)
      uri = URI.parse(actor_uri)
      return nil unless uri.is_a?(URI::HTTP) && uri.scheme == "https"
      return nil if Federation::SsrfGuard.blocked_host?(uri.host)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5
      resp = http.get(uri.request_uri, { "Accept" => "application/activity+json" })
      return nil unless resp.code == "200"
      doc = JSON.parse(resp.body)
      doc.dig("publicKey", "publicKeyPem")
    rescue StandardError
      nil
    end

    def self.parse_sig_header(header)
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
