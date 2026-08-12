# UniFed backend — modular monolith (Rails API-only).
# NOTE: uses Ruby 3.3 (not 4.0) on purpose: rails/rake boot cleanly here,
# whereas the local Ruby 4.0 has a Thor parser break that blocks `rails s`.
FROM ruby:3.3-slim

ENV RAILS_ENV=production \
    RACK_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/gems \
    BUNDLE_WITHOUT="development:test"

# System deps: postgres client (schema load), build toolchain for native gems.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential libpq-dev postgresql-client curl \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems first (layer cache).
COPY backend/Gemfile backend/Gemfile.lock ./
RUN gem install bundler -v "$(grep -A1 'BUNDLED WITH' Gemfile.lock | tail -1)" \
    && bundle lock --add-platform x86_64-linux && bundle install --jobs 4

# App source.
COPY backend/ ./backend/
# The authoritative schema SQL lives at repo root (db/schema/*.sql).
COPY db/ ./db/

WORKDIR /app/backend
RUN bundle lock --add-platform x86_64-linux

EXPOSE 3000

# Load schema (psql, deterministic — no rails needed) then seed on first boot.
COPY backend/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["puma", "-p", "3000", "-e", "production"]
