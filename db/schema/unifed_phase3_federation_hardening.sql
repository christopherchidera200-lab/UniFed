-- Federation hardening (P0-5). Mirrors db/migrate/20260815000004_create_federation_hardening.rb.
CREATE TABLE IF NOT EXISTS federation_follows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_uri text NOT NULL,
  followed_actor_id uuid NOT NULL,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS index_federation_follows_uniq ON federation_follows (follower_uri, followed_actor_id);

CREATE TABLE IF NOT EXISTS federation_processed_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ap_id text NOT NULL,
  actor_uri text,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS index_federation_processed_activities_on_ap_id ON federation_processed_activities (ap_id);

ALTER TABLE federation_follows ADD CONSTRAINT fk_federation_follows_actor FOREIGN KEY (followed_actor_id) REFERENCES federation_actors (id);

ALTER TABLE federation_activities ADD COLUMN IF NOT EXISTS deleted_at timestamp;
CREATE INDEX IF NOT EXISTS index_federation_activities_on_deleted_at ON federation_activities (deleted_at);
