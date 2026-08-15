class CreateFederationHardening < ActiveRecord::Migration[7.1]
  def up
    # F-05: persisted follow edges (auto-accept currently no-ops).
    create_table :federation_follows, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.string :follower_uri, null: false
      t.uuid :followed_actor_id, null: false
      t.timestamps
    end
    add_foreign_key :federation_follows, :federation_actors, column: :followed_actor_id
    add_index :federation_follows, [:follower_uri, :followed_actor_id], unique: true

    # F-06: replay protection — one row per processed activity id.
    create_table :federation_processed_activities, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.string :ap_id, null: false
      t.string :actor_uri
      t.timestamps
    end
    add_index :federation_processed_activities, :ap_id, unique: true

    # F-05: tombstone column for Delete handling on the activity table.
    add_column :federation_activities, :deleted_at, :timestamp
    add_index :federation_activities, :deleted_at
  end

  def down
    drop_table :federation_processed_activities
    drop_table :federation_follows
  end
end
