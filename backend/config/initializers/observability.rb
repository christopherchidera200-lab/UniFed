# Load observability + API-edge hardening middleware (Phase 0 hardening) and
# mount them. Observability is always on; rate-limit and secure headers are
# env-gated so local/dev run without Redis/HSTS.
require_relative "../../app/services/observability/metrics"
require_relative "../../lib/metrics_middleware"
require_relative "../../lib/rate_limit_middleware"
require_relative "../../lib/secure_headers_middleware"

Rails.application.configure do
  config.middleware.use MetricsMiddleware
  config.middleware.use SecureHeadersMiddleware
  config.middleware.use RateLimitMiddleware if ENV["RATE_LIMIT_ENABLED"] == "true"
end
