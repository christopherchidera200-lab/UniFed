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

# Establish ONE test connection and make every model use it. This app boots on
# a non-standard Ruby where repeated establish_connection/reconnect calls can
# spawn divergent pools; pinning a single connection here keeps the spec's
# queries and the cleanup truncation on the same pool.
ActiveRecord::Base.connection_pool.disconnect! if ActiveRecord::Base.connected?
ActiveRecord::Base.establish_connection(:test)

require "rspec/rails"
require "factory_bot_rails"

# Load factories (flat file at spec/factories.rb; factory_bot_rails only
# auto-discovers spec/factories/**/*.rb, so require it explicitly).
require Rails.root.join("spec/factories")

RSpec.configure do |config|
  # Fixtures are disabled: this app boots on a non-standard Ruby where the
  # auto-established test connection does not participate in the example
  # transaction, so we manage cleanup ourselves (see before(:each) below).
  config.use_transactional_fixtures = false
  config.fixture_paths = []
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  # Truncate all tables before every example so each example starts clean and
  # sequence-generated unique attributes (slug, code, matric_no, ...) never
  # collide with leftover rows. Uses the single pinned test connection above.
  config.before(:each) do
    ActiveRecord::Base.connection.tables.each do |t|
      klass = t.classify.safe_constantize
      if klass && klass < ActiveRecord::Base
        klass.delete_all
      else
        ActiveRecord::Base.connection.execute("DELETE FROM #{t}")
      end
    end
  end
end
