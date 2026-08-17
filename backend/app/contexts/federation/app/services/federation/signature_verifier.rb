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

    def self.verify(request:, actor_uri:)
      sig_header = request.headers["Signature"].to_s
      return false if sig_header.blank?

      params = parse_sig_header(sig_header)
      return false unless params["keyId"] && params["signature"]

      # The actor that signed must be the actor named in the activity.
      key_actor_uri = params["keyId"].gsub(/#main-key\z/, "")
      return false if actor_uri.present? && key_actor_uri != actor_uri.gsub(/#main-key\z/, "")

      pub = public_key_for(key_actor_uri)
      return false unless pub

      signed_string = build_signed_string(request, params["headers"])
      begin
        pub.verify(OpenSSL::Digest::SHA256.new, Base64.strict_decode64(params["signature"]), signed_string)
      rescue OpenSSL::PKey::RSAError, ArgumentError
        false
      end
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

      # F-04 SSRF guard: resolve the host and reject internal/link-local/
      # metadata IP ranges before connecting. A remote actor key fetch must
      # never reach cloud metadata (169.254.169.254) or private networks.
      return nil if ssrf_blocked?(uri.host)

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

    # Returns true if the host resolves to a non-public address (SSRF risk).
    # Blocks private / loopback / link-local (e.g. 169.254.169.254 metadata)
    # ranges; allows everything else.
    def self.ssrf_blocked?(host)
      return true if host.blank?
      # Literal IP: validate directly (no DNS needed).
      if host.match?(/\A\d{1,3}(\.\d{1,3}){3}\z/)
        ip = IPAddr.new(host) rescue nil
        return true if ip.nil?
        return true if ip.loopback? || ip.link_local? || ip.private?
        return false
      end
      # Hostname: resolve and reject if any address is non-public.
      resolved = Addrinfo.getaddrinfo(host, "https", :INET, :STREAM, nil,
                                      Socket::AI_NUMERICHOST | Socket::AI_NUMERICSERV).map(&:ip_address)
      resolved.any? do |addr|
        ip = IPAddr.new(addr) rescue nil
        ip.nil? || ip.loopback? || ip.link_local? || ip.private?
      end
    rescue SocketError, Errno::ECONNREFUSED, StandardError
      true
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
