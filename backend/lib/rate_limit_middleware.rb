# Rate limiting middleware (Phase 0 hardening). Fixed-window per IP, backed by
# the already-installed redis gem. Env-gated: disabled unless
# RATE_LIMIT_ENABLED=true (production). Swap for rack-attack later if desired.
class RateLimitMiddleware
  def initialize(app)
    @app = app
    @enabled = ENV["RATE_LIMIT_ENABLED"] == "true"
    @limit = (ENV.fetch("RATE_LIMIT_PER_MIN", "120")).to_i
    @window = 60
    @redis = nil
    if @enabled
      require "redis"
      @redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    end
  end

  def call(env)
    return @app.call(env) unless @enabled

    # F-03: never trust a raw, attacker-controlled X-Forwarded-For. Derive the
    # client IP via ActionDispatch::Request#remote_ip, which honours
    # config.action_dispatch.trusted_proxies (set to the reverse-proxy range in
    # production) and ignores spoofable headers. Falls back to REMOTE_ADDR.
    req = ActionDispatch::Request.new(env)
    ip = req.remote_ip || env["REMOTE_ADDR"]
    key = "ratelimit:#{ip}:#{env['PATH_INFO']}"
    count = @redis.multi do |r|
      r.incr(key)
      r.expire(key, @window)
    end.first

    if count.to_i > @limit
      [429, { "Content-Type" => "application/json", "Retry-After" => @window.to_s },
       [{ error: "rate_limited", retry_after: @window }.to_json]]
    else
      @app.call(env)
    end
  rescue Redis::BaseError, StandardError
    # Fail open: never block traffic if Redis is unavailable.
    @app.call(env)
  end
end
