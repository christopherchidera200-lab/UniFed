-- Campus / Smart-Campus tables (P0-1). Mirrors db/migrate/20260815000001_create_campus_context.rb.
-- Applied directly to the dev/test Postgres because this DB is loaded from
-- authoritative DDL (no schema_migrations tracking).
CREATE TABLE IF NOT EXISTS campus_campuses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid NOT NULL,
  name text NOT NULL,
  address text,
  center_lat numeric(10,7),
  center_lng numeric(10,7),
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS index_campus_campuses_on_university_id ON campus_campuses (university_id);

CREATE TABLE IF NOT EXISTS campus_places (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid NOT NULL,
  campus_id uuid NOT NULL,
  name text NOT NULL,
  kind text NOT NULL,
  description text,
  lat numeric(10,7),
  lng numeric(10,7),
  accessibility_level numeric(2,1) DEFAULT 0,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS index_campus_places_on_university_id ON campus_places (university_id);
CREATE INDEX IF NOT EXISTS index_campus_places_on_campus_id ON campus_places (campus_id);
CREATE INDEX IF NOT EXISTS index_campus_places_on_kind ON campus_places (kind);

ALTER TABLE campus_places
  ADD CONSTRAINT fk_campus_places_campus FOREIGN KEY (campus_id)
  REFERENCES campus_campuses (id);
-- universities FK only if the table exists (it does in this schema).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'universities') THEN
    ALTER TABLE campus_campuses
      ADD CONSTRAINT fk_campus_campuses_university FOREIGN KEY (university_id)
      REFERENCES universities (id);
    ALTER TABLE campus_places
      ADD CONSTRAINT fk_campus_places_university FOREIGN KEY (university_id)
      REFERENCES universities (id);
  END IF;
END $$;
