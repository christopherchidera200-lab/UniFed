# Phase 1 — Social domain (Home feed, posts, stories, polls, comments, reactions).
# Mirrors db/schema/unifed_phase1_social.sql. PostgreSQL 16.
class CreateSocialPhase1 < ActiveRecord::Migration[7.1]
  def change
    create_table :social_posts, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id, null: false
      t.uuid :author_id
      t.text :body, null: false
      t.string :visibility, null: false, default: "university"
      t.boolean :federated, default: false
      t.string :ap_id
      t.timestamps
      t.index :ap_id, unique: true, where: "ap_id IS NOT NULL"
      t.foreign_key :universities, column: :university_id, on_delete: :cascade
    end
    create_table :social_stories, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id, null: false
      t.uuid :author_id, null: false
      t.string :media_url, null: false
      t.timestamp :expires_at
      t.timestamps
      t.foreign_key :universities, column: :university_id, on_delete: :cascade
    end
    create_table :social_short_videos, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id, null: false
      t.uuid :author_id, null: false
      t.string :media_url, null: false
      t.timestamps
      t.foreign_key :universities, column: :university_id, on_delete: :cascade
    end
    create_table :social_polls, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id, null: false
      t.uuid :author_id, null: false
      t.string :question, null: false
      t.jsonb :options, default: [], null: false
      t.timestamps
      t.foreign_key :universities, column: :university_id, on_delete: :cascade
    end
    create_table :social_poll_votes, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :poll_id, null: false
      t.uuid :voter_id, null: false
      t.integer :option_index, null: false
      t.timestamps
      t.foreign_key :social_polls, column: :poll_id, on_delete: :cascade
    end
    create_table :social_comments, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :post_id, null: false
      t.uuid :author_id, null: false
      t.text :body, null: false
      t.timestamps
      t.foreign_key :social_posts, column: :post_id, on_delete: :cascade
    end
    create_table :social_reactions, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :post_id, null: false
      t.uuid :author_id, null: false
      t.string :kind, null: false, default: "like"
      t.timestamps
      t.index %i[post_id author_id], unique: true, name: "uniq_social_reactions_post_author"
      t.foreign_key :social_posts, column: :post_id, on_delete: :cascade
    end
    create_table :social_feed_entries, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :post_id, null: false
      t.uuid :university_id, null: false
      t.float :rank, default: 0.0
      t.timestamps
      t.foreign_key :social_posts, column: :post_id, on_delete: :cascade
      t.foreign_key :universities, column: :university_id, on_delete: :cascade
    end
  end
end
