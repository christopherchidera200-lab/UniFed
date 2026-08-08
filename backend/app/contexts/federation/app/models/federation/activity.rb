module Federation
  # A single ActivityPub activity (Create/Update/Delete/Follow/...). Local
  # activities are fanned out to remote inboxes via Delivery records.
  class Activity < ApplicationRecord
    self.table_name = "federation_activities"

    belongs_to :actor, class_name: "Federation::Actor"
    has_many :deliveries, class_name: "Federation::Delivery", dependent: :destroy

    validates :activity_type, presence: true
    validates :object_type, presence: true
    validates :object_uri, presence: true, uniqueness: { scope: :actor_id }

    def to_json_ld
      {
        "@context" => "https://www.w3.org/ns/activitystreams",
        "id" => "#{actor.actor_uri}/activities/#{id}",
        "type" => activity_type,
        "actor" => actor.actor_uri,
        "object" => payload
      }
    end
  end
end
