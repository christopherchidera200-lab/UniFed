-- Phase 0 — Identity, RBAC, Audit, NDPA consent. PostgreSQL 16.
-- Mirrors db/migrate/20260807000001_create_identity_phase0.rb.

CREATE TABLE IF NOT EXISTS identity_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
  email text NOT NULL,
  username text NOT NULL,
  display_name text,
  actor_type text NOT NULL DEFAULT 'student',
  actor_id uuid,
  status text NOT NULL DEFAULT 'active',
  mfa_enrolled boolean NOT NULL DEFAULT false,
  webauthn_challenge text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uniq_identity_users_uni_email UNIQUE (university_id, email),
  CONSTRAINT uniq_identity_users_uni_username UNIQUE (university_id, username)
);
CREATE INDEX IF NOT EXISTS idx_identity_users_email ON identity_users (email);

CREATE TABLE IF NOT EXISTS identity_credentials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES identity_users(id) ON DELETE CASCADE,
  kind text NOT NULL,
  secret_enc text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uniq_identity_credentials_user_kind UNIQUE (user_id, kind)
);

CREATE TABLE IF NOT EXISTS identity_mfa_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES identity_users(id) ON DELETE CASCADE,
  kind text NOT NULL,
  label text,
  secret_enc text,
  credential_id text,
  public_key text,
  confirmed boolean NOT NULL DEFAULT false,
  last_used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS identity_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES identity_users(id) ON DELETE CASCADE,
  jti text NOT NULL,
  refresh_jti text NOT NULL,
  ip text,
  user_agent text,
  expired_at timestamptz NOT NULL,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uniq_identity_sessions_jti UNIQUE (jti),
  CONSTRAINT uniq_identity_sessions_refresh_jti UNIQUE (refresh_jti)
);

CREATE TABLE IF NOT EXISTS identity_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
  name text NOT NULL,
  permissions jsonb NOT NULL DEFAULT '[]',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uniq_identity_roles_uni_name UNIQUE (university_id, name)
);

CREATE TABLE IF NOT EXISTS identity_role_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES identity_users(id) ON DELETE CASCADE,
  role_id uuid NOT NULL REFERENCES identity_roles(id) ON DELETE CASCADE,
  scope_type text NOT NULL DEFAULT 'university',
  scope_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uniq_identity_role_assignments UNIQUE (user_id, role_id, scope_type, scope_id)
);

CREATE TABLE IF NOT EXISTS identity_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid REFERENCES universities(id) ON DELETE CASCADE,
  actor_type text,
  actor_id uuid,
  action text NOT NULL,
  ip text,
  meta jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_identity_audit_action ON identity_audit_logs (action);
CREATE INDEX IF NOT EXISTS idx_identity_audit_created ON identity_audit_logs (created_at);

CREATE TABLE IF NOT EXISTS identity_consent_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES identity_users(id) ON DELETE CASCADE,
  purpose text NOT NULL,
  granted boolean NOT NULL DEFAULT false,
  withdrawn_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uniq_identity_consent_user_purpose UNIQUE (user_id, purpose)
);
