require "resolv"
require "ipaddr"

module Federation
  # Shared SSRF guard for any outbound HTTP the federation layer performs
  # (remote actor documents, remote public keys). Resolves the host and refuses
  # loopback, RFC1918, link-local / cloud-metadata, and IPv6 equivalents,
  # failing closed on DNS failure or a blank host. Rejects before any socket is
  # opened (vuln-0001 / vuln-0002).
  module SsrfGuard
    BLOCKED_RANGES = [
      IPAddr.new("127.0.0.0/8"),       # loopback
      IPAddr.new("10.0.0.0/8"),        # RFC1918
      IPAddr.new("172.16.0.0/12"),      # RFC1918
      IPAddr.new("192.168.0.0/16"),     # RFC1918
      IPAddr.new("169.254.0.0/16"),     # link-local (incl. cloud metadata)
      IPAddr.new("169.254.169.254/32"), # AWS/GCP metadata endpoint
      IPAddr.new("::1/128"),            # IPv6 loopback
      IPAddr.new("fe80::/10"),          # IPv6 link-local
      IPAddr.new("fc00::/7")            # IPv6 unique-local
    ].freeze

    def self.blocked_host?(host)
      return true if host.blank?

      begin
        ips = Resolv.getaddresses(host)
      rescue Resolv::ResolvError
        return true # fail closed if DNS resolution fails
      end

      ips.empty? || ips.any? do |ip|
        addr = IPAddr.new(ip)
        addr.loopback? || BLOCKED_RANGES.any? { |range| range.include?(addr) }
      end
    rescue IPAddr::InvalidAddress
      true # fail closed on an unparseable address
    end
  end
end
