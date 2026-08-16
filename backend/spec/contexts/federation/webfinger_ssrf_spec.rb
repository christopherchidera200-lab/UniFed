require "rails_helper"

RSpec.describe Federation::WebfingerService, type: :service do
  describe ".fetch_actor_document" do
    # A fake Net::HTTP that records whether #get was called and returns a
    # 200 with a JSON actor document.
    let(:fake_http) do
      Class.new do
        attr_reader :get_called

        def use_ssl=(_v); end
        def open_timeout=(_v); end
        def read_timeout=(_v); end
        def max_redirects=(_v); end

        def get(_uri, _headers)
          @get_called = true
          resp = Object.new
          resp.define_singleton_method(:code) { "200" }
          resp.define_singleton_method(:body) { '{"type":"Person"}' }
          resp
        end
      end.new
    end

    before do
      allow(Net::HTTP).to receive(:new).and_return(fake_http)
    end

    it "never issues an HTTP request to a blocked host" do
      # 169.254.169.254 is cloud metadata — must be refused before any socket.
      expect(Net::HTTP).not_to receive(:new)
      expect(described_class.fetch_actor_document("https://169.254.169.254/latest/meta-data/")).to be_nil
    end

    %w[127.0.0.1 10.0.0.1 172.16.0.1 192.168.1.1 ::1].each do |host|
      it "refuses to fetch from internal host #{host} without an HTTP call" do
        expect(Net::HTTP).not_to receive(:new)
        described_class.fetch_actor_document("https://#{host}/actors/alice")
      end
    end

    it "refuses non-https schemes" do
      expect(Net::HTTP).not_to receive(:new)
      expect(described_class.fetch_actor_document("http://example.com/actors/alice")).to be_nil
    end

    it "fetches a guarded public host and parses the document" do
      # Allow the host through the guard; the HTTP layer is stubbed below.
      allow(Federation::SsrfGuard).to receive(:blocked_host?).and_return(false)
      result = described_class.fetch_actor_document("https://remote.example.edu/actors/alice")
      expect(result).to eq("type" => "Person")
      expect(fake_http.get_called).to be(true)
    end
  end
end
