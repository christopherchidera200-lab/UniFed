#!/bin/sh
# Boot entrypoint for the UniFed backend container.
# Loads the authoritative schema SQL (repo-root db/schema/*.sql) into Postgres,
# runs seeds once, then execs the server.
set -e
export PGPASSWORD="$DATABASE_PASSWORD"

echo "== waiting for postgres =="
until pg_isready -h "$DATABASE_HOST" -U "$DATABASE_USER" >/dev/null 2>&1; do
  sleep 1
done

echo "== loading schema (db/schema/*.sql) =="
for f in /app/db/schema/*.sql; do
  echo "   $f"
  psql -h "$DATABASE_HOST" -U "$DATABASE_USER" -d "$DATABASE_NAME" -v ON_ERROR_STOP=1 -f "$f" || true
done

echo "== seeding (idempotent) =="
bundle exec rails runner db/seeds.rb || true

echo "== starting server =="
exec bundle exec "$@"
