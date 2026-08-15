module Federation
  # Replay cache (F-06). One row per processed activity id; inserting a
  # duplicate raises a unique violation, which the inbox handler treats as a
  # replay and rejects. Prunable by created_at.
  class ProcessedActivity < ::ApplicationRecord
    self.table_name = "federation_processed_activities"

    validates :ap_id, presence: true, uniqueness: true

    # Returns true if this activity id was already seen (replay).
    def self.replayed?(ap_id)
      where(ap_id: ap_id).exists?
    end

    # Records the activity id; raises ActiveRecord::RecordNotUnique on replay.
    def self.record!(ap_id, actor_uri = nil)
      create!(ap_id: ap_id, actor_uri: actor_uri)
    end
  end
end
