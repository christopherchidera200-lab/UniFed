class CreateResearchContext < ActiveRecord::Migration[7.1]
  def up
    create_table :research_profiles, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :user_id, null: false
      t.uuid :university_id, null: false
      t.string :title
      t.text :bio
      t.string :orcid
      t.text :research_fields, array: true, default: []
      t.integer :citations_count, default: 0
      t.timestamps
    end
    add_index :research_profiles, :user_id, unique: true
    add_index :research_profiles, :university_id

    create_table :research_groups, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id, null: false
      t.string :name, null: false
      t.text :description
      t.uuid :lead_id
      t.timestamps
    end
    add_index :research_groups, :university_id

    create_table :research_group_memberships, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :group_id, null: false
      t.uuid :user_id, null: false
      t.string :role, default: "member"
      t.timestamps
    end
    add_foreign_key :research_group_memberships, :research_groups, column: :group_id
    add_index :research_group_memberships, [:group_id, :user_id], unique: true

    create_table :research_publications, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :group_id
      t.uuid :profile_id
      t.uuid :university_id, null: false
      t.string :title, null: false
      t.text :abstract
      t.text :authors, array: true, default: []
      t.string :doi
      t.string :venue
      t.integer :year
      t.timestamps
    end
    add_index :research_publications, :group_id
    add_index :research_publications, :profile_id
    add_index :research_publications, :university_id

    create_table :research_projects, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :group_id, null: false
      t.uuid :university_id, null: false
      t.string :title, null: false
      t.text :summary
      t.string :status, default: "active"
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
    add_foreign_key :research_projects, :research_groups, column: :group_id
    add_index :research_projects, :group_id
    add_index :research_projects, :university_id
  end

  def down
    drop_table :research_projects
    drop_table :research_publications
    drop_table :research_group_memberships
    drop_table :research_groups
    drop_table :research_profiles
  end
end
