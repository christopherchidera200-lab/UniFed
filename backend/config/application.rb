require_relative "boot"

require "rails/all"

# Require the modular-monolith contexts (engines) explicitly.
Dir.glob(File.expand_path("../app/contexts/*/lib/*.rb", __dir__)).sort.each { |f| require f }

Bundler.require(*Rails.groups)

module UniFed
  class Application < Rails::Application
    config.load_defaults 7.1

    # DDD: isolate contexts; eager-load across engines.
    config.autoload_paths << Rails.root.join("app/contexts")
    config.eager_load_paths << Rails.root.join("app/contexts")

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
