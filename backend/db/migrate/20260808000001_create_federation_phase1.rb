# Phase 1 — Federation (ActivityPub) tables + private key column.
# Mirrors db/schema/unifed_phase1_federation.sql. PostgreSQL 16.
class CreateFederationPhase1 < ActiveRecord::Migration[7.1]
  def change
    add_column :federation_actors, :private_key_pem, :text unless column_exists?(:federation_actors, :private_key_pem)
    add_column :federation_actors, :display_name, :string unless column_exists?(:federation_actors, :display_name)

    create_table :federation_activities, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :actor_id, null: false
      t.string :activity_type, null: false
      t.string :object_type, null: false
      t.string :object_uri, null: false
      t.jsonb :payload, default: {}, null: false
      t.boolean :delivered, default: false
      t.timestamps
      t.index %i[actor_id object_uri], unique: true, name: "uniq_fed_activities_actor_object"
      t.foreign_key :federation_actors, column: :actor_id, on_delete: :cascade
    end

    create_table :federation_deliveries, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :activity_id, null: false
      t.string :target_inbox, null: false
      t.string :status, default: "pending"
      t.integer :attempts, default: 0
      t.text :last_error
      t.timestamp :last_attempt_at
      t.timestamps
      t.foreign_key :federation_activities, column: :activity_id, on_delete: :cascade
    end
  end
end
