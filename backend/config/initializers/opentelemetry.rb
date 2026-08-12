# OpenTelemetry init (Phase 0 hardening). Env-gated: only activates when
# OTEL_EXPORTER_OTLP_ENDPOINT is set (production). In dev/test it's a no-op so
# specs don't need a collector. Structured request logs via lograge.
if Rails.application.config.respond_to?(:lograge)
  Rails.application.configure do
    config.lograge.enabled = !Rails.env.test?
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.custom_options = lambda do |event|
      { request_id: event.payload[:request_id],
        trace_id: (Thread.current[:otel_trace_id] if defined?(Thread.current[:otel_trace_id])) }
    end
  end
end

if ENV["OTEL_EXPORTER_OTLP_ENDPOINT"].present?
  require "opentelemetry/sdk"
  require "opentelemetry/exporter/otlp"
  require "opentelemetry/instrumentation/rails"
  require "opentelemetry/instrumentation/rack"

  OpenTelemetry::SDK.configure do |c|
    c.service_name = ENV.fetch("OTEL_SERVICE_NAME", "unifed-backend")
    c.use "OpenTelemetry::Instrumentation::Rack"
    c.use "OpenTelemetry::Instrumentation::Rails"
  end
end
