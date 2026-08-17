require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

# NOTE: bounded-context namespaces (Academic::, Records::, StudentId::) are
# required explicitly from spec/rails_helper.rb (and any runner) AFTER the
# Rails environment boots, so ApplicationRecord is available. We intentionally
# do NOT require them here at boot, to avoid loading models before AR is ready.


module UniFed
  class Application < Rails::Application
    config.load_defaults 7.1

    # DDD modular monolith: each context under app/contexts/<ctx> owns its
    # models/services. Namespaces are defined explicitly by the context
    # loaders (app/contexts/<ctx>/lib/<ctx>.rb, required at the top of this
    # file) — so we ignore app/contexts in Zeitwerk to avoid inflection
    # conflicts and let the explicit requires own those constants.
    Rails.autoloaders.main.ignore(Rails.root.join("app/contexts"))

    # API-first: no default view rendering, JSON only.
    config.api_only = true

    # Secure-by-default: SSL is enforced in production only (see production.rb).
    # Setting it here (globally) would also force it in test, redirecting every
    # request spec to https://www.example.com and breaking request tests.
    config.action_dispatch.cookies_same_site_protection = :strict

    # Twelve-factor: logs to stdout. Use lograge for structured JSON request
    # logs when the gem is available (it registers config.lograge via its
    # railtie); guard so a missing/optional lograge doesn't crash boot.
    if config.respond_to?(:lograge)
      config.lograge.enabled = true
      config.lograge.formats = [:json]
    end

    # OIDC issuer for this node (per-deployment override via ENV).
    config.x.oidc_issuer = ENV.fetch("OIDC_ISSUER", "https://adun.unifed.ng")
    # Audience the API tokens are bound to (F-02). Distinct from the issuer so
    # a token minted for one purpose cannot be replayed elsewhere. Per-deployment
    # override via ENV; defaults to "<issuer>/api".
    config.x.oidc_audience = ENV.fetch("OIDC_AUDIENCE", "#{config.x.oidc_issuer}/api")
    config.x.node_slug   = ENV.fetch("NODE_SLUG", "adun")
    config.x.node_university_id = ENV.fetch("NODE_UNIVERSITY_ID", nil)
    config.x.federation_enabled = ENV.fetch("FEDERATION_ENABLED", "true") == "true"
    # Consent policy version stamped on every consent record (NDPA lawful-basis audit).
    # Bump this when the privacy policy / consent terms change so older grants are identifiable.
    config.x.consent_policy_version = ENV.fetch("CONSENT_POLICY_VERSION", "1.0")
  end
end
