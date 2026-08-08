# Secure response headers middleware (Phase 0 hardening). Sets baseline
# security headers on every response. No external gem needed.
class SecureHeadersMiddleware
  HEADERS = {
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "DENY",
    "X-XSS-Protection" => "1; mode=block",
    "Referrer-Policy" => "strict-origin-when-cross-origin",
    "Permissions-Policy" => "geolocation=(), microphone=(), camera=()",
    "Content-Security-Policy" => [
      "default-src 'self'",
      "img-src 'self' data: https:",
      "style-src 'self' 'unsafe-inline'",
      "script-src 'self'",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'"
    ].join("; ")
  }.freeze

  def initialize(app)
    @app = app
    @hsts = ENV["SECURE_HEADERS_HSTS"] == "true"
  end

  def call(env)
    status, headers, body = @app.call(env)
    HEADERS.each { |k, v| headers[k] ||= v }
    headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains; preload" if @hsts
    [status, headers, body]
  end
end
