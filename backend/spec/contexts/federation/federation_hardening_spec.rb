require "rails_helper"

RSpec.describe "Federation hardening (F-04/F-05/F-06)", type: :service do
  let(:university) { create(:university) }
  before { UniFed::Application.config.x.node_university_id = university.id }

  # --- F-04: signature verification ---
  describe "SignatureVerifier (F-04)" do
    it "rejects when the signing keyId does not match the claimed actor" do
      key = OpenSSL::PKey::RSA.new(2048)
      actor = create(:federation_actor, public_key_pem: key.public_key.to_pem)
      signed_string = "(request-target): post /inbox\nhost: adun.unifed.ng\ndate: now"
      sig = Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, signed_string))
      sig_header = %(keyId="#{actor.actor_uri}#main-key",algorithm="rsa-sha256",headers="(request-target) host date",signature="#{sig}")
      req = Object.new
      def req.headers; @h; end
      def req.request_method; "POST"; end
      def req.fullpath; "/inbox"; end
      req.instance_variable_set(:@h, { "Signature" => sig_header, "host" => "adun.unifed.ng", "date" => "now" })
      # Claiming a DIFFERENT actor in the body must fail even with a valid sig.
      expect(Federation::SignatureVerifier.verify(request: req, actor_uri: "https://evil.edu/actors/x")).to be false
    end

    it "accepts a valid signature from the matching actor" do
      key = OpenSSL::PKey::RSA.new(2048)
      actor = create(:federation_actor, public_key_pem: key.public_key.to_pem)
      signed_string = "(request-target): post /inbox\nhost: adun.unifed.ng\ndate: now"
      sig = Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, signed_string))
      sig_header = %(keyId="#{actor.actor_uri}#main-key",algorithm="rsa-sha256",headers="(request-target) host date",signature="#{sig}")
      req = Object.new
      def req.headers; @h; end
      def req.request_method; "POST"; end
      def req.fullpath; "/inbox"; end
      req.instance_variable_set(:@h, { "Signature" => sig_header, "host" => "adun.unifed.ng", "date" => "now" })
      expect(Federation::SignatureVerifier.verify(request: req, actor_uri: actor.actor_uri)).to be true
    end
  end

  # --- F-05: Follow creates a persisted edge; Delete tombstones ---
  describe "InboxHandler Follow/Delete (F-05)" do
    let(:local_actor) { Federation::ActorProvisioningService.provision(university) }

    it "persists a Follow edge instead of no-op" do
      body = { "type" => "Follow", "actor" => "https://remote.edu/actors/bob@remote.edu",
               "object" => local_actor.actor_uri, "id" => "https://remote.edu/activities/f1" }
      allow(Federation::SignatureVerifier).to receive(:verify).and_return(true)
      result, status = Federation::InboxHandler.handle(actor: local_actor, body: body, request: double("r"))
      expect(status).to eq(:ok)
      expect(Federation::Follow.find_by(follower_uri: "https://remote.edu/actors/bob@remote.edu",
                                        followed_actor: local_actor)).to be_present
    end

    it "tombstones a referenced activity on Delete" do
      act = Federation::Activity.create!(actor: local_actor, activity_type: "Create",
                                          object_type: "Note", object_uri: "https://remote.edu/obj/del1")
      body = { "type" => "Delete", "actor" => local_actor.actor_uri,
               "object" => "https://remote.edu/obj/del1", "id" => "https://remote.edu/activities/del1" }
      allow(Federation::SignatureVerifier).to receive(:verify).and_return(true)
      result, status = Federation::InboxHandler.handle(actor: local_actor, body: body, request: double("r"))
      expect(status).to eq(:ok)
      expect(act.reload.deleted_at).to be_present
    end
  end

  # --- F-06: replay protection ---
  describe "InboxHandler replay protection (F-06)" do
    let(:local_actor) { Federation::ActorProvisioningService.provision(university) }

    it "rejects a second delivery of the same activity id" do
      body = { "type" => "Create", "actor" => local_actor.actor_uri, "id" => "https://remote.edu/activities/dup1",
               "object" => { "type" => "Note", "id" => "https://remote.edu/obj/dup1", "content" => "x" } }
      allow(Federation::SignatureVerifier).to receive(:verify).and_return(true)
      allow(Social::Post).to receive(:create_from_ap).and_return(nil) if defined?(Social::Post)
      r1, s1 = Federation::InboxHandler.handle(actor: local_actor, body: body, request: double("r"))
      expect(s1).to eq(:ok)
      r2, s2 = Federation::InboxHandler.handle(actor: local_actor, body: body, request: double("r"))
      expect(s2).to eq(:unprocessable_entity)
      expect(r2[:error]).to eq("replay_detected")
    end
  end
end
