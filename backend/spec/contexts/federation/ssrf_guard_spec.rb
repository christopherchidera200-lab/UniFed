require "rails_helper"

RSpec.describe Federation::SsrfGuard, type: :service do
  describe ".blocked_host?" do
    # The exact ranges the findings register requires to be rejected before any
    # outbound request is attempted (vuln-0001 / vuln-0002).
    blocked = {
      "AWS metadata IPv4"   => "169.254.169.254",
      "link-local IPv4"     => "169.254.1.1",
      "loopback IPv4"       => "127.0.0.1",
      "RFC1918 10/8"        => "10.0.0.5",
      "RFC1918 172.16/12"   => "172.16.0.1",
      "RFC1918 192.168/16"  => "192.168.1.1",
      "IPv6 loopback"       => "::1",
      "IPv6 link-local"     => "fe80::1",
      "IPv6 unique-local"   => "fc00::1"
    }

    blocked.each do |label, host|
      it "blocks #{label} (#{host})" do
        expect(described_class.blocked_host?(host)).to be(true)
      end
    end

    it "blocks a blank host" do
      expect(described_class.blocked_host?("")).to be(true)
      expect(described_class.blocked_host?(nil)).to be(true)
    end

    it "blocks a host that fails DNS resolution (fail-closed)" do
      allow(Resolv).to receive(:getaddresses).and_raise(Resolv::ResolvError.new("nxdomain"))
      expect(described_class.blocked_host?("does-not-exist.invalid")).to be(true)
    end

    it "allows a routable public host" do
      # Hermetic: stub DNS to return a routable public IP.
      allow(Resolv).to receive(:getaddresses).with("public.example").and_return(["203.0.113.10"])
      expect(described_class.blocked_host?("public.example")).to be(false)
    end
  end
end
