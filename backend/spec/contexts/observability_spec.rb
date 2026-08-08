require "rails_helper"

RSpec.describe Observability::Metrics, type: :service do
  before { Observability::Metrics.reset! }

  it "counts requests and auth failures, and computes avg latency" do
    Observability::Metrics.observe_request(status: 200, latency_ms: 100)
    Observability::Metrics.observe_request(status: 401, latency_ms: 50)
    Observability::Metrics.inc_auth_failure
    Observability::Metrics.inc_federation(direction: :in)
    Observability::Metrics.inc_federation(direction: :out)

    prom = Observability::Metrics.to_prometheus
    expect(prom).to include("unifed_requests_total 2")
    expect(prom).to include('unifed_requests_by_status{code="200"} 1')
    expect(prom).to include("unifed_auth_failures_total 1")
    expect(prom).to include("unifed_federation_in_total 1")
    expect(prom).to include("unifed_federation_out_total 1")
    expect(prom).to include("unifed_request_latency_ms_avg 75.0")
  end
end

RSpec.describe "Metrics endpoint", type: :request do
  it "exposes Prometheus-format metrics" do
    get "/metrics"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("unifed_requests_total")
  end
end

RSpec.describe SecureHeadersMiddleware do
  let(:app) { ->(_env) { [200, {}, ["ok"]] } }
  let(:middleware) { SecureHeadersMiddleware.new(app) }

  it "adds baseline security headers" do
    status, headers, _body = middleware.call({ "PATH_INFO" => "/x" })
    expect(status).to eq(200)
    expect(headers["X-Content-Type-Options"]).to eq("nosniff")
    expect(headers["X-Frame-Options"]).to eq("DENY")
    expect(headers["Content-Security-Policy"]).to include("frame-ancestors 'none'")
  end
end

RSpec.describe MetricsMiddleware do
  let(:app) { ->(_env) { [200, {}, ["ok"]] } }
  let(:middleware) { MetricsMiddleware.new(app) }

  it "records request metrics" do
    Observability::Metrics.reset!
    middleware.call({ "PATH_INFO" => "/api/v1/feed" })
    expect(Observability::Metrics.to_prometheus).to include("unifed_requests_total 1")
  end
end
