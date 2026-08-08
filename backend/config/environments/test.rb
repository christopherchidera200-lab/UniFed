# Use the test database for the test environment.
Rails.application.configure do
  # Settings specified here will take precedence over those in production.rb.

  config.cache_classes = true
  config.eager_load = false
  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = :none
  config.action_controller.allow_forgery_protection = false

  # No SSL in test — otherwise ActionDispatch::SSL redirects every request to
  # https://www.example.com and request specs fail with 301/308.
  config.force_ssl = false

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable caching in test.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.cache_store = :memory_store
    config.public_file_server.headers = { "Cache-Control" => "public, max-age=#{1.hour.to_i}" }
  else
    config.cache_store = :null_store
  end
end
