# Lightweight in-process metrics exposed at /metrics in Prometheus text format.
# Avoids a hard dependency on the prometheus gem while still giving SLO-grade
# counters. Swap for prometheus-client + exporter in production if desired.
module Observability
  class Metrics
    MUTEX = Mutex.new
    STATE = {
      requests_total: 0,
      requests_by_status: Hash.new(0),
      auth_failures_total: 0,
      federation_in_total: 0,
      federation_out_total: 0,
      latency_ms_sum: 0,
      latency_ms_count: 0
    }

    def self.observe_request(status:, latency_ms:)
      MUTEX.synchronize do
        STATE[:requests_total] += 1
        STATE[:requests_by_status][status] += 1
        STATE[:latency_ms_sum] += latency_ms
        STATE[:latency_ms_count] += 1
      end
    end

    def self.inc_auth_failure
      MUTEX.synchronize { STATE[:auth_failures_total] += 1 }
    end

    def self.inc_federation(direction:)
      MUTEX.synchronize { STATE[direction == :in ? :federation_in_total : :federation_out_total] += 1 }
    end

    # Prometheus text exposition format.
    def self.to_prometheus
      MUTEX.synchronize do
        avg = STATE[:latency_ms_count].zero? ? 0 : (STATE[:latency_ms_sum].to_f / STATE[:latency_ms_count]).round(2)
        lines = []
        lines << "# HELP unifed_requests_total Total HTTP requests." 
        lines << "# TYPE unifed_requests_total counter"
        lines << "unifed_requests_total #{STATE[:requests_total]}"
        lines << "# HELP unifed_requests_by_status Total HTTP requests by status code."
        lines << "# TYPE unifed_requests_by_status counter"
        STATE[:requests_by_status].each { |s, c| lines << "unifed_requests_by_status{code=\"#{s}\"} #{c}" }
        lines << "# HELP unifed_auth_failures_total Failed authentications."
        lines << "# TYPE unifed_auth_failures_total counter"
        lines << "unifed_auth_failures_total #{STATE[:auth_failures_total]}"
        lines << "# HELP unifed_federation_in_total Inbound federation activities."
        lines << "# TYPE unifed_federation_in_total counter"
        lines << "unifed_federation_in_total #{STATE[:federation_in_total]}"
        lines << "# HELP unifed_federation_out_total Outbound federation deliveries."
        lines << "# TYPE unifed_federation_out_total counter"
        lines << "unifed_federation_out_total #{STATE[:federation_out_total]}"
        lines << "# HELP unifed_request_latency_ms_avg Average request latency (ms)."
        lines << "# TYPE unifed_request_latency_ms_avg gauge"
        lines << "unifed_request_latency_ms_avg #{avg}"
        lines.join("\n") + "\n"
      end
    end

    def self.reset!
      MUTEX.synchronize do
        STATE[:requests_total] = 0
        STATE[:requests_by_status].clear
        STATE[:auth_failures_total] = 0
        STATE[:federation_in_total] = 0
        STATE[:federation_out_total] = 0
        STATE[:latency_ms_sum] = 0
        STATE[:latency_ms_count] = 0
      end
    end
  end
end
