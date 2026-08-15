module Federation
  # A persisted follow edge (F-05). Replaces the previous auto-accept no-op so
  # follows are recorded and can be audited / revoked.
  class Follow < ::ApplicationRecord
    self.table_name = "federation_follows"
    belongs_to :followed_actor, class_name: "Federation::Actor"

    validates :follower_uri, presence: true
    validates :follower_uri, uniqueness: { scope: :followed_actor_id }
  end
end
