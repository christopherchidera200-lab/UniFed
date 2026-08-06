require_relative "boot"

require "rails/all"

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

    # Secure-by-default.
    config.force_ssl = true
    config.action_dispatch.cookies_same_site_protection = :strict

    # Twelve-factor: logs to stdout.
    config.lograge.enabled = true
    config.lograge.formats = [:json]

    # OIDC issuer for this node (per-deployment override via ENV).
    config.x.oidc_issuer = ENV.fetch("OIDC_ISSUER", "https://adun.unifed.ng")
    config.x.node_slug   = ENV.fetch("NODE_SLUG", "adun")
    config.x.federation_enabled = ENV.fetch("FEDERATION_ENABLED", "true") == "true"
  end
end
