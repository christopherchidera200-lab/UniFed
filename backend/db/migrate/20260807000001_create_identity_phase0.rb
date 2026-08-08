# Phase 0 — Identity, RBAC, Audit, NDPA consent + MFA columns.
# Mirrors db/schema/unifed_phase0.sql. PostgreSQL 16.
class CreateIdentityPhase0 < ActiveRecord::Migration[7.1]
  def change
    # ---- Identity core ----
    create_table :identity_users, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id, null: false
      t.string :email, null: false
      t.string :username, null: false
      t.string :display_name
      t.string :actor_type, null: false, default: "student"
      t.uuid :actor_id
      t.string :status, null: false, default: "active"
      t.boolean :mfa_enrolled, default: false, null: false
      t.string :webauthn_challenge
      t.timestamps
      t.index :email, unique: true
      t.index %i[university_id email], unique: true, name: "uniq_identity_users_uni_email"
      t.index %i[university_id username], unique: true, name: "uniq_identity_users_uni_username"
      t.foreign_key :universities, column: :university_id, on_delete: :cascade
    end

    create_table :identity_credentials, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :user_id, null: false
      t.string :kind, null: false
      t.text :secret_enc
      t.timestamps
      t.index %i[user_id kind], unique: true, name: "uniq_identity_credentials_user_kind"
      t.foreign_key :identity_users, column: :user_id, on_delete: :cascade
    end

    create_table :identity_mfa_devices, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :user_id, null: false
      t.string :kind, null: false
      t.string :label
      t.text :secret_enc
      t.string :credential_id
      t.text :public_key
      t.boolean :confirmed, default: false, null: false
      t.timestamp :last_used_at
      t.timestamps
      t.foreign_key :identity_users, column: :user_id, on_delete: :cascade
    end

    create_table :identity_sessions, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :user_id, null: false
      t.string :jti, null: false
      t.string :refresh_jti, null: false
      t.string :ip
      t.string :user_agent
      t.timestamp :expired_at, null: false
      t.timestamp :revoked_at
      t.timestamps
      t.index :jti, unique: true
      t.index :refresh_jti, unique: true
      t.foreign_key :identity_users, column: :user_id, on_delete: :cascade
    end

    create_table :identity_roles, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id, null: false
      t.string :name, null: false
      t.jsonb :permissions, default: [], null: false
      t.timestamps
      t.index %i[university_id name], unique: true, name: "uniq_identity_roles_uni_name"
      t.foreign_key :universities, column: :university_id, on_delete: :cascade
    end

    create_table :identity_role_assignments, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :user_id, null: false
      t.uuid :role_id, null: false
      t.string :scope_type, null: false, default: "university"
      t.uuid :scope_id
      t.timestamps
      t.index %i[user_id role_id scope_type scope_id],
              unique: true, name: "uniq_identity_role_assignments"
      t.foreign_key :identity_users, column: :user_id, on_delete: :cascade
      t.foreign_key :identity_roles, column: :role_id, on_delete: :cascade
    end

    create_table :identity_audit_logs, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id
      t.string :actor_type
      t.uuid :actor_id
      t.string :action, null: false
      t.string :ip
      t.jsonb :meta, default: {}, null: false
      t.timestamps
      t.index :action
      t.index :created_at
      t.foreign_key :universities, column: :university_id, on_delete: :cascade
    end

    create_table :identity_consent_records, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :user_id, null: false
      t.string :purpose, null: false
      t.boolean :granted, default: false, null: false
      t.timestamp :withdrawn_at
      t.timestamps
      t.index %i[user_id purpose], unique: true, name: "uniq_identity_consent_user_purpose"
      t.foreign_key :identity_users, column: :user_id, on_delete: :cascade
    end
  end
end
