module Federation
  require "net/http"
  # Resolves a remote actor from a handle (user@host) or actor URI via
  # WebFinger + the actor document. Caches the public key on a remote Actor row.
  class WebfingerService
    # resource like "acct:alice@remote.edu" or a full actor URI.
    def self.resolve(resource, fetch: true)
      uri = acct_to_uri(resource)
      return nil unless uri
      actor = Federation::Actor.find_by(actor_uri: uri)
      return actor if actor && actor.public_key_pem.present?

      return nil unless fetch
      doc = fetch_actor_document(uri)
      return nil unless doc

      Federation::Actor.create!(
        university_id: UniFed::Application.config.x.node_university_id,
        actor_type: doc["type"] == "Organization" ? "university" : "user",
        actor_uri: uri,
        inbox_url: doc["inbox"],
        outbox_url: doc["outbox"],
        public_key_pem: doc.dig("publicKey", "publicKeyPem")
      )
    rescue ActiveRecord::RecordNotUnique
      Federation::Actor.find_by(actor_uri: uri)
    end

    def self.acct_to_uri(resource)
      if resource.start_with?("http")
        resource
      elsif resource.start_with?("acct:")
        _, handle = resource.split(":", 2)
        user, host = handle.split("@")
        "#{UniFed::Application.config.x.oidc_issuer}/actors/#{user}@#{host}"
      else
        nil
      end
    end

    def self.fetch_actor_document(uri)
      parsed = URI.parse(uri.to_s)
      return nil unless parsed.is_a?(URI::HTTP) && parsed.scheme == "https"
      return nil if SsrfGuard.blocked_host?(parsed.host)

      http = Net::HTTP.new(parsed.host, parsed.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5
      # Net::HTTP does not follow redirects by default, so there is no
      # redirect-based SSRF vector here.
      resp = http.get(parsed.request_uri, { "Accept" => "application/activity+json" })
      return nil unless resp.code == "200"
      JSON.parse(resp.body)
    rescue StandardError
      nil
    end
  end
end
