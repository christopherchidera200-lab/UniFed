Rails.application.configure do
  config.cache_classes = true
  config.eager_load = ENV.fetch("RAILS_ENV", "development") == "production"
  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"] == "true"
  config.lograge.enabled = true
  config.log_level = :info

  # Secure-by-default: enforce HTTPS in production.
  config.force_ssl = true
end
