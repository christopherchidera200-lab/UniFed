-- Phase 1 — Search + Profile supporting tables. PostgreSQL 16.
-- Mirrors db/migrate/20260810000001_create_search_profile_phase1.rb.

CREATE TABLE IF NOT EXISTS search_saved_searches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES identity_users(id) ON DELETE CASCADE,
  query text NOT NULL,
  filters jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS profile_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES identity_users(id) ON DELETE CASCADE,
  bio text,
  skills jsonb NOT NULL DEFAULT '[]',
  portfolio jsonb NOT NULL DEFAULT '[]',
  social_links jsonb NOT NULL DEFAULT '{}',
  creator boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uniq_profile_profiles_user UNIQUE (user_id)
);
