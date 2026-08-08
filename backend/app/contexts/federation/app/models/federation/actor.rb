module Federation
  # An ActivityPub actor. The university instance is itself the root actor
  # (e.g. @adun@unifed.ng); users/communities are subordinate actors. Local
  # actors hold a keypair; remote actors store only the public key (fetched
  # via Webfinger/actor document).
  class Actor < ApplicationRecord
    self.table_name = "federation_actors"

    belongs_to :university, class_name: "Academic::University"
    has_many :activities, class_name: "Federation::Activity", foreign_key: :actor_id, dependent: :destroy
    has_many :outgoing_deliveries, class_name: "Federation::Delivery", foreign_key: :activity_id

    validates :actor_uri, presence: true, uniqueness: true
    validates :actor_type, inclusion: { in: %w[university user group] }
    validates :inbox_url, :outbox_url, :public_key_pem, presence: true

    # AP actor document (minimal, Mastodon-compatible).
    def to_actor_document
      {
        "@context" => [
          "https://www.w3.org/ns/activitystreams",
          "https://w3id.org/security/v1"
        ],
        "id" => actor_uri,
        "type" => actor_type == "university" ? "Organization" : "Person",
        "preferredUsername" => preferred_username,
        "name" => display_name,
        "inbox" => inbox_url,
        "outbox" => outbox_url,
        "publicKey" => {
          "id" => "#{actor_uri}#main-key",
          "owner" => actor_uri,
          "publicKeyPem" => public_key_pem
        }
      }
    end

    def preferred_username
      actor_uri.split("@").last
    end

    def local?
      actor_uri.start_with?("#{UniFed::Application.config.x.oidc_issuer}/actors")
    end
  end
end
