# Prometheus-style metrics endpoint (Phase 0 hardening). Public scrape target.
class MetricsController < ActionController::Metal
  action :show

  def show
    self.content_type = "text/plain; version=0.0.4; charset=utf-8"
    self.response_body = Observability::Metrics.to_prometheus
    self.status = 200
  end
end
