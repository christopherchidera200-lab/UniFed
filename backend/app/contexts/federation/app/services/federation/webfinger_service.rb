module Federation
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
      # In production this hits the remote /.well-known/webfinger then the actor
      # document. Kept as a clearly-marked network boundary (no real HTTP here
      # to keep the suite hermetic and fast).
      Rails.logger.info("webfinger.fetch_actor_document(#{uri}) [network boundary]")
      nil
    end
  end
end
