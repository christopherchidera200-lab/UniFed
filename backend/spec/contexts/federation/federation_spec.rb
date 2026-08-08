require "rails_helper"

RSpec.describe Federation::ActorProvisioningService, type: :service do
  let(:university) { create(:university) }

  it "provisions a root actor with a keypair and is idempotent" do
    actor = Federation::ActorProvisioningService.provision(university)
    expect(actor).to be_persisted
    expect(actor.actor_type).to eq("university")
    expect(actor.public_key_pem).to include("PUBLIC KEY")
    expect(actor.private_key_pem).to be_present

    # Idempotent
    again = Federation::ActorProvisioningService.provision(university)
    expect(again.id).to eq(actor.id)
  end

  it "renders a valid AP actor document" do
    actor = Federation::ActorProvisioningService.provision(university)
    doc = actor.to_actor_document
    expect(doc["id"]).to eq(actor.actor_uri)
    expect(doc["publicKey"]["publicKeyPem"]).to eq(actor.public_key_pem)
  end
end

RSpec.describe Federation::DeliveryService, type: :service do
  let(:university) { create(:university) }

  it "queues deliveries to recipient inboxes" do
    actor = Federation::ActorProvisioningService.provision(university)
    remote = create(:federation_actor, actor_uri: "https://remote.edu/actors/bob@remote.edu",
                    inbox_url: "https://remote.edu/inbox", university: university)
    activity = Federation::DeliveryService.deliver(
      actor: actor,
      activity_type: "Create",
      object: { "type" => "Note", "id" => "https://adun.unifed.ng/objects/1", "content" => "hi" },
      recipients: [remote.actor_uri]
    )
    expect(activity).to be_persisted
    expect(activity.deliveries.count).to eq(1)
    expect(activity.deliveries.first.target_inbox).to eq("https://remote.edu/inbox")
  end
end

RSpec.describe Federation::SignatureVerifier, type: :service do
  it "accepts a correctly signed request and rejects a tampered one" do
    key = OpenSSL::PKey::RSA.new(2048)
    actor = create(:federation_actor, public_key_pem: key.public_key.to_pem)

    signed_string = "(request-target): post /inbox\nhost: adun.unifed.ng\ndate: now"
    sig = Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, signed_string))
    sig_header = %(keyId="#{actor.actor_uri}#main-key",algorithm="rsa-sha256",headers="(request-target) host date",signature="#{sig}")

    good_request = Object.new
    def good_request.headers; @h; end
    def good_request.request_method; "POST"; end
    def good_request.fullpath; "/inbox"; end
    good_request.instance_variable_set(:@h, { "Signature" => sig_header, "host" => "adun.unifed.ng", "date" => "now" })

    expect(Federation::SignatureVerifier.verify(request: good_request, actor_uri: actor.actor_uri)).to be true

    bad_sig = Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, "tampered"))
    bad_header = %(keyId="#{actor.actor_uri}#main-key",algorithm="rsa-sha256",headers="(request-target) host date",signature="#{bad_sig}")
    bad_request = Object.new
    def bad_request.headers; @h; end
    def bad_request.request_method; "POST"; end
    def bad_request.fullpath; "/inbox"; end
    bad_request.instance_variable_set(:@h, { "Signature" => bad_header, "host" => "adun.unifed.ng", "date" => "now" })

    expect(Federation::SignatureVerifier.verify(request: bad_request, actor_uri: actor.actor_uri)).to be false
  end
end

RSpec.describe Federation::InboxHandler, type: :service do
  let(:university) { create(:university) }
  let(:local_actor) { Federation::ActorProvisioningService.provision(university) }

  before do
    UniFed::Application.config.x.node_university_id = university.id
  end

  it "creates a local Post from a federated Create Note (Social context present)" do
    body = {
      "type" => "Create",
      "actor" => local_actor.actor_uri,
      "object" => { "type" => "Note", "id" => "https://remote.edu/obj/9", "content" => "federated post" }
    }
    allow(Federation::SignatureVerifier).to receive(:verify).and_return(true)
    fake_request = double("req")
    result, status = Federation::InboxHandler.handle(actor: local_actor, body: body, request: fake_request)
    expect(status).to eq(:ok)
    expect(Social::Post.find_by(ap_id: "https://remote.edu/obj/9")).to be_present
  end
end
