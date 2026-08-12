# CORS configuration (rack-cors). Allows the frontend origin(s) to call the
# API from the browser. Origins are env-driven so staging/production can
# restrict to their real domain(s) via CORS_ORIGINS (comma-separated).
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("CORS_ORIGINS", "http://localhost:3001").split(",").map(&:strip)

    resource "/api/*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
