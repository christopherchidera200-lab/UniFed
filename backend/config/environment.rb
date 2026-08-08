require_relative "boot"
require "rails/all"
Bundler.require(*Rails.groups)

require_relative "../lib/unifed"

module UniFed
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    # NOTE: app/contexts is ignored by Zeitwerk (see application.rb) and its
    # constants are required explicitly by the context loaders / rails_helper.
    config.action_dispatch.cookies_same_site_protection = :strict
    config.lograge.enabled = true
    config.lograge.formats = [:json]
    config.x.oidc_issuer = ENV.fetch("OIDC_ISSUER", "https://adun.unifed.ng")
    config.x.node_slug   = ENV.fetch("NODE_SLUG", "adun")
    config.x.federation_enabled = ENV.fetch("FEDERATION_ENABLED", "true") == "true"
  end
end
