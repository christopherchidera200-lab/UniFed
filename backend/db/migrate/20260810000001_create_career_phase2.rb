# Career Hub (Phase 2): employer profiles, opportunities, applications, saved jobs.
class CreateCareerPhase2 < ActiveRecord::Migration[7.1]
  def change
    create_table :employer_profiles do |t|
      t.references :university, null: true, foreign_key: true
      t.text :name, null: false
      t.text :industry
      t.text :website
      t.text :description
      t.boolean :verified, null: false, default: false
      t.timestamps
    end

    create_table :career_opportunities do |t|
      t.references :employer_profile, null: false, foreign_key: true
      t.text :title, null: false
      t.text :description
      t.text :employment_type, null: false
      t.text :location_type
      t.text :location
      t.boolean :remote
      t.text :salary_range
      t.integer :min_level
      t.text :status, null: false, default: "open"
      t.timestamps
    end

    create_table :career_applications do |t|
      t.references :student, null: false, foreign_key: { to_table: :students }
      t.references :career_opportunity, null: false, foreign_key: true
      t.references :employer_profile, null: true, foreign_key: true
      t.text :cover_note
      t.text :status, null: false, default: "submitted"
      t.timestamps
    end

    create_table :saved_jobs do |t|
      t.references :student, null: false, foreign_key: { to_table: :students }
      t.references :career_opportunity, null: false, foreign_key: true
      t.timestamps
    end

    add_index :career_opportunities, :employment_type
    add_index :career_opportunities, :status
    add_index :career_opportunities, :min_level
    add_index :career_applications, %i[student_id career_opportunity_id], unique: true
    add_index :saved_jobs, %i[student_id career_opportunity_id], unique: true
    add_index :career_opportunities, :title, opclass: :gin_trgm_ops, using: :gin
  end
end
