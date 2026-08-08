module Federation
  # Provisions the root university actor for an instance and stores its keypair.
  # Called during instance bootstrap (Phase 0 deploy / setup task).
  class ActorProvisioningService
    def self.provision(university)
      base = UniFed::Application.config.x.oidc_issuer
      uri = "#{base}/actors/#{university.slug}@#{URI(base).host}"
      return Federation::Actor.find_by(actor_uri: uri) if Federation::Actor.exists?(actor_uri: uri)

      kp = KeyService.generate_keypair
      Federation::Actor.create!(
        university: university,
        actor_type: "university",
        actor_uri: uri,
        inbox_url: "#{base}/api/v1/federation/inbox?id=#{URI.encode_www_form_component(uri)}",
        outbox_url: "#{base}/api/v1/federation/outbox?id=#{URI.encode_www_form_component(uri)}",
        public_key_pem: kp[:public_pem],
        private_key_pem: KeyService.encrypt_private(kp[:private_pem])
      )
    end
  end
end
