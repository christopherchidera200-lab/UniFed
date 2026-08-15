# Configure Rails Environment for testing
ENV["RAILS_ENV"] = "test"

require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Explicitly load the DDD bounded-context namespaces (Academic::, Records::,
# StudentId::) now that the Rails environment (and ::ApplicationRecord) is up.
# The context loaders (app/contexts/<ctx>/lib/<ctx>.rb) require their
# models/services. Required here (not only via the initializer) so specs always
# see the constants regardless of boot path.
require Rails.root.join("app/models/application_record")
Dir[Rails.root.join("app/contexts/*/lib/*.rb")].sort.each { |f| require f }

# Observability support (app/services/observability) is not under an autoload
# path and its initializer is skipped on this non-standard boot, so require it
# explicitly. Mirrors config/initializers/observability.rb for the test path.
require Rails.root.join("app/services/observability/metrics")
require Rails.root.join("lib/metrics_middleware")
require Rails.root.join("lib/secure_headers_middleware")
require Rails.root.join("lib/rate_limit_middleware")

# Explicitly load the database configuration. On this non-standard Ruby the
# minimal `config/environment` boot does not reliably populate
# ActiveRecord::Base.configurations (and database.yml uses ERB, which plain
# YAML parsing does not evaluate), so we load it ourselves: run ERB, parse
# YAML, register the config, then establish the single test connection.
require "erb"
db_raw = ERB.new(File.read(Rails.root.join("config/database.yml"))).result
db_hash = YAML.safe_load(db_raw, aliases: true, permitted_classes: [Symbol])
ActiveRecord::Base.configurations = ActiveRecord::DatabaseConfigurations.new(db_hash)
ActiveRecord::Base.connection_pool.disconnect! if ActiveRecord::Base.connected?
ActiveRecord::Base.establish_connection(:test)

# The minimal boot path above skips Rails.application.initialize!, so the
# Rails logger is never set up (production boots fine via initialize!). Request
# specs call `get`, which logs through a nil logger and raises. Provide a
# fallback stdout logger for the test environment only.
unless Rails.logger
  Rails.logger = ActiveSupport::Logger.new($stdout)
  Rails.application.config.logger = Rails.logger if Rails.application.config.respond_to?(:logger)
end

# The minimal boot path skips Rails.application.initialize!, which (a) draws
# config/routes.rb and (b) initializes + populates Zeitwerk's autoload paths.
# Without it the router is empty (every request 404s) and app/* are not
# autoloaded. Register the standard dirs then set up the autoloader, and draw
# routes here for the test environment; production boots via initialize!.
begin
  %w[app/controllers app/controllers/concerns app/models app/models/concerns app/services].each do |d|
    Rails.autoloaders.main.push_dir(Rails.root.join(d)) if Rails.root.join(d).exist?
  end
  Rails.autoloaders.each(&:setup)
rescue StandardError
  nil
end
if Rails.application.routes.respond_to?(:draw) && Rails.application.routes.routes.empty?
  load Rails.root.join("config/routes.rb")
end

require "rspec/rails"
require "factory_bot_rails"

# Factories live in the flat file spec/factories.rb. factory_bot_rails'
# definition glob (spec/factories/**/*.rb, which also matches the flat file)
# auto-loads them during the Rails boot, so do NOT require them explicitly
# here — a second load re-evaluates FactoryBot.define and raises
# FactoryBot::DuplicateDefinitionError (registered sequences/factories).

RSpec.configure do |config|
  # Fixtures are disabled: this app boots on a non-standard Ruby where the
  # auto-established test connection does not participate in the example
  # transaction, so we manage cleanup ourselves (see before(:each) below).
  config.use_transactional_fixtures = false
  config.fixture_paths = []
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  # Test federation node. CI/test loads schema only (never seeds), so the node
  # university must exist for node-scoped PUBLIC browse endpoints to resolve.
  # Set on config.x (read live by BaseController#node_university) and re-created
  # after every truncate in the cleanup below.
  TEST_NODE_UNIVERSITY_ID = "00000000-0000-0000-0000-00000000aa".freeze
  UniFed::Application.config.x.node_university_id = TEST_NODE_UNIVERSITY_ID

  # Truncate all tables before every example so each example starts clean and
  # sequence-generated unique attributes (slug, code, matric_no, ...) never
  # collide with leftover rows. A single multi-table TRUNCATE ... CASCADE
  # (re)orders foreign keys for us, so it is both FK-safe and fast.
  config.before(:each) do
    tables = ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata]
    ActiveRecord::Base.connection.execute(
      "TRUNCATE #{tables.map { |t| ActiveRecord::Base.connection.quote_table_name(t) }.join(", ")} RESTART IDENTITY CASCADE"
    )

    # Re-create the test node university (wiped by the truncate above) so
    # node-scoped public browse endpoints have a university to scope to.
    Academic::University.find_or_create_by(id: TEST_NODE_UNIVERSITY_ID) do |u|
      u.slug = "test-node"
      u.name = "Test Node University"
      u.kind = "public"
      u.country_iso = "ng"
    end
  end
end
