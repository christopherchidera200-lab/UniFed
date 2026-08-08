# Phase 1 — Search + Profile supporting tables.
# Mirrors db/schema/unifed_phase1_search_profile.sql. PostgreSQL 16.
class CreateSearchProfilePhase1 < ActiveRecord::Migration[7.1]
  def change
    create_table :search_saved_searches, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id, null: false
      t.uuid :user_id, null: false
      t.string :query, null: false
      t.jsonb :filters, default: {}, null: false
      t.timestamps
      t.foreign_key :universities, column: :university_id, on_delete: :cascade
      t.foreign_key :identity_users, column: :user_id, on_delete: :cascade
    end

    create_table :profile_profiles, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :user_id, null: false
      t.text :bio
      t.jsonb :skills, default: [], null: false
      t.jsonb :portfolio, default: [], null: false
      t.jsonb :social_links, default: {}, null: false
      t.boolean :creator, default: false
      t.timestamps
      t.index :user_id, unique: true
      t.foreign_key :identity_users, column: :user_id, on_delete: :cascade
    end
  end
end
