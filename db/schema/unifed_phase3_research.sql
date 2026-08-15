-- Research Hub context (P0-3). Mirrors db/migrate/20260815000003_create_research_context.rb.
CREATE TABLE IF NOT EXISTS research_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  university_id uuid NOT NULL,
  title text,
  bio text,
  orcid text,
  research_fields text[] DEFAULT '{}',
  citations_count integer DEFAULT 0,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS index_research_profiles_on_user_id ON research_profiles (user_id);
CREATE INDEX IF NOT EXISTS index_research_profiles_on_university_id ON research_profiles (university_id);

CREATE TABLE IF NOT EXISTS research_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid NOT NULL,
  name text NOT NULL,
  description text,
  lead_id uuid,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS index_research_groups_on_university_id ON research_groups (university_id);

CREATE TABLE IF NOT EXISTS research_group_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role text DEFAULT 'member',
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS index_research_group_memberships_uniq ON research_group_memberships (group_id, user_id);

CREATE TABLE IF NOT EXISTS research_publications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid,
  profile_id uuid,
  university_id uuid NOT NULL,
  title text NOT NULL,
  abstract text,
  authors text[] DEFAULT '{}',
  doi text,
  venue text,
  year integer,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS index_research_publications_on_group_id ON research_publications (group_id);
CREATE INDEX IF NOT EXISTS index_research_publications_on_profile_id ON research_publications (profile_id);
CREATE INDEX IF NOT EXISTS index_research_publications_on_university_id ON research_publications (university_id);

CREATE TABLE IF NOT EXISTS research_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL,
  university_id uuid NOT NULL,
  title text NOT NULL,
  summary text,
  status text DEFAULT 'active',
  start_date date,
  end_date date,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS index_research_projects_on_group_id ON research_projects (group_id);
CREATE INDEX IF NOT EXISTS index_research_projects_on_university_id ON research_projects (university_id);

ALTER TABLE research_group_memberships ADD CONSTRAINT fk_research_memberships_group FOREIGN KEY (group_id) REFERENCES research_groups (id);
ALTER TABLE research_projects ADD CONSTRAINT fk_research_projects_group FOREIGN KEY (group_id) REFERENCES research_groups (id);
