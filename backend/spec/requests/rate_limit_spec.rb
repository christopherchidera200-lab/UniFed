require "rails_helper"

RSpec.describe RateLimitMiddleware, type: :request do
  # F-03: the limiter must key on the trusted client IP, not a raw
  # attacker-controlled X-Forwarded-For. With a fixed REMOTE_ADDR and rotating
  # XFF, repeated requests must hit the 429 cap (not be spread across keys).

  let(:app) do
    Class.new do
      def call(env)
        [200, { "Content-Type" => "application/json" }, [{ ok: true }.to_json]]
      end
    end.new
  end

  def build_env(remote_addr:, xff: nil)
    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/api/v1/catalog/courses",
      "REMOTE_ADDR" => remote_addr,
      "rack.input" => StringIO.new
    }
    env["HTTP_X_FORWARDED_FOR"] = xff if xff
    env
  end

  around do |example|
    saved = {
      "RATE_LIMIT_ENABLED" => ENV["RATE_LIMIT_ENABLED"],
      "RATE_LIMIT_PER_MIN" => ENV["RATE_LIMIT_PER_MIN"],
      "REDIS_URL" => ENV["REDIS_URL"]
    }
    ENV["RATE_LIMIT_ENABLED"] = "true"
    ENV["RATE_LIMIT_PER_MIN"] = "3"
    ENV["REDIS_URL"] = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
    example.run
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  it "blocks when the same client IP exceeds the limit, ignoring spoofed XFF" do
    mw = described_class.new(app)
    remote = "203.0.113.7"

    statuses = 3.times.map do |i|
      mw.call(build_env(remote_addr: remote, xff: "10.0.0.#{i}"))[0]
    end
    fourth = mw.call(build_env(remote_addr: remote, xff: "10.0.0.999"))[0]

    expect(statuses).to all(eq(200))
    expect(fourth).to eq(429)
  end
end
