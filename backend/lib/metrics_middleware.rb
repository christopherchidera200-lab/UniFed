# Rack middleware: records request latency + status into Observability::Metrics.
# Runs for every request; lightweight (mutex-guarded counters).
class MetricsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    start = (Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000).to_i
    status, headers, body = @app.call(env)
    latency = (Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000).to_i - start
    # Skip the scrape endpoint itself to avoid metric pollution.
    unless env["PATH_INFO"] == "/metrics"
      Observability::Metrics.observe_request(status: status, latency_ms: latency)
    end
    [status, headers, body]
  rescue StandardError
    Observability::Metrics.observe_request(status: 500, latency_ms: 0)
    raise
  end
end
