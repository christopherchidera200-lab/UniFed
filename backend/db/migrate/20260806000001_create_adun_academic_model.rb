# Database schema — ADUN academic model (M1).
# Authoritative DDL: db/schema/adun_academic_model.sql
# This migration is the Rails-managed equivalent.
class CreateAdunAcademicModel < ActiveRecord::Migration[7.1]
  def change
    enable_extension "pgcrypto"
    enable_extension "pg_trgm"

    create_table :universities, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.string :slug, null: false
      t.string :name, null: false
      t.string :short_name
      t.string :kind, null: false, default: "federal"
      t.string :owner
      t.string :country_iso, limit: 2, null: false, default: "NG"
      t.text :actor_uri
      t.boolean :federation_enabled, null: false, default: false
      t.jsonb :config_json, null: false, default: {}
      t.timestamps
      t.index :slug, unique: true
      t.index :actor_uri, unique: true
    end

    create_table :faculties, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :university, type: :uuid, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :dean_name
      t.integer :founding_year
      t.timestamps
      t.index [:university_id, :code], unique: true
    end

    create_table :departments, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :faculty, type: :uuid, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :hod_name
      t.timestamps
      t.index [:faculty_id, :code], unique: true
    end

    create_table :programmes, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :department, type: :uuid, null: false, foreign_key: { to_table: :departments }
      t.string :code, null: false
      t.string :name, null: false
      t.string :degree_type, null: false
      t.integer :duration_years, null: false
      t.timestamps
      t.index [:department_id, :code], unique: true
    end

    create_table :courses, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :programme, type: :uuid, null: false, foreign_key: true
      t.string :code, null: false
      t.string :title, null: false
      t.integer :credit_units, null: false
      t.integer :level, null: false
      t.integer :semester, null: false
      t.uuid :prerequisites, array: true, default: []
      t.timestamps
      t.index [:programme_id, :code], unique: true
      t.index :code, using: :gin, opclass: :gin_trgm_ops
    end

    create_table :academic_sessions, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :university, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.boolean :is_current, null: false, default: false
      t.timestamps
      t.index [:university_id, :name], unique: true
    end

    create_table :semesters, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :academic_session, type: :uuid, null: false, foreign_key: true
      t.integer :number, null: false
      t.date :lecture_start, null: false
      t.date :lecture_end, null: false
      t.date :exam_start, null: false
      t.date :exam_end, null: false
      t.date :registration_open
      t.date :registration_close
      t.date :break_start
      t.date :break_end
      t.timestamps
      t.index [:academic_session_id, :number], unique: true
    end

    create_table :lecturers, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :university, type: :uuid, null: false, foreign_key: true
      t.string :staff_id
      t.string :full_name, null: false
      t.references :department, type: :uuid, foreign_key: true
      t.string :title
      t.timestamps
      t.index :university_id
      t.index :department_id
    end

    create_table :students, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :university, type: :uuid, null: false, foreign_key: true
      t.string :matric_no, null: false
      t.integer :entry_year, null: false
      t.string :entry_mode, null: false
      t.integer :current_level, null: false
      t.string :status, null: false, default: "active"
      t.string :identity_subject
      t.timestamps
      t.index [:university_id, :matric_no], unique: true
      t.index :identity_subject, unique: true
    end

    create_table :student_enrollments, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :student, type: :uuid, null: false, foreign_key: true
      t.references :programme, type: :uuid, null: false, foreign_key: true
      t.references :academic_session, type: :uuid, null: false, foreign_key: true
      t.boolean :is_primary, null: false, default: true
      t.timestamps
      t.index [:student_id, :programme_id, :academic_session_id], unique: true
    end

    create_table :course_offerings, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :course, type: :uuid, null: false, foreign_key: true
      t.references :academic_session, type: :uuid, null: false, foreign_key: true
      t.integer :semester_number, null: false
      t.references :lecturer, type: :uuid, foreign_key: true
      t.timestamps
      t.index [:course_id, :academic_session_id, :semester_number], unique: true
    end

    create_table :grade_records, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :student, type: :uuid, null: false, foreign_key: true
      t.references :course_offering, type: :uuid, null: false, foreign_key: true
      t.decimal :score, precision: 5, scale: 2
      t.string :grade_letter, limit: 2
      t.decimal :grade_point, precision: 3, scale: 2
      t.boolean :is_published, null: false, default: false
      t.string :recorded_by
      t.timestamp :recorded_at, null: false, default: -> { "now()" }
      t.timestamps
      t.index [:student_id, :course_offering_id], unique: true
    end

    create_table :academic_summaries, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :student, type: :uuid, null: false, foreign_key: true
      t.references :academic_session, type: :uuid, foreign_key: true
      t.decimal :total_credits, precision: 6, scale: 2, null: false, default: 0
      t.decimal :gpa, precision: 4, scale: 2
      t.decimal :cgpa, precision: 4, scale: 2
      t.string :class_of_degree
      t.timestamp :updated_at, null: false, default: -> { "now()" }
      t.index [:student_id, :academic_session_id], unique: true
    end

    create_table :digital_student_ids, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :student, type: :uuid, null: false, foreign_key: true
      t.string :token_hash, null: false
      t.jsonb :qr_payload, null: false, default: {}
      t.string :status, null: false, default: "active"
      t.timestamp :issued_at, null: false, default: -> { "now()" }
      t.timestamp :expires_at, null: false
      t.timestamp :revoked_at
      t.timestamps
      t.index :token_hash, unique: true
      t.index :student_id
    end

    create_table :id_verification_logs, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :digital_student_id, type: :uuid, null: false, foreign_key: true
      t.string :verifier_actor, null: false
      t.boolean :result, null: false
      t.timestamp :verified_at, null: false, default: -> { "now()" }
      t.inet :ip_address
      t.text :user_agent
      t.index :digital_id_id
    end

    create_table :events, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :university, type: :uuid, null: false, foreign_key: true
      t.string :title, null: false
      t.string :type, null: false
      t.timestamp :event_start, null: false
      t.timestamp :event_end
      t.references :faculty, type: :uuid, foreign_key: true
      t.references :department, type: :uuid, foreign_key: true
      t.timestamps
      t.index :university_id
      t.index :type
      t.index :event_start
    end

    create_table :federation_actors, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.references :university, type: :uuid, null: false, foreign_key: true
      t.string :actor_type, null: false
      t.text :actor_uri, null: false
      t.text :inbox_url, null: false
      t.text :outbox_url, null: false
      t.text :public_key_pem, null: false
      t.timestamps
      t.index :university_id
      t.index :actor_uri, unique: true
    end
  end
end
