-- Phase 1 — Federation (ActivityPub) additions. PostgreSQL 16.
-- Mirrors db/migrate/20260808000001_create_federation_phase1.rb.

ALTER TABLE federation_actors ADD COLUMN IF NOT EXISTS private_key_pem text;
ALTER TABLE federation_actors ADD COLUMN IF NOT EXISTS display_name text;

CREATE TABLE IF NOT EXISTS federation_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid NOT NULL REFERENCES federation_actors(id) ON DELETE CASCADE,
  activity_type text NOT NULL,
  object_type text NOT NULL,
  object_uri text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}',
  delivered boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uniq_fed_activities_actor_object UNIQUE (actor_id, object_uri)
);

CREATE TABLE IF NOT EXISTS federation_deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id uuid NOT NULL REFERENCES federation_activities(id) ON DELETE CASCADE,
  target_inbox text NOT NULL,
  status text DEFAULT 'pending',
  attempts integer DEFAULT 0,
  last_error text,
  last_attempt_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
