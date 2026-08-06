# Configure Rails Environment for testing
ENV["RAILS_ENV"] = "test"

require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Explicitly load the DDD bounded-context namespaces (Academic, Records,
# StudentId) after the Rails environment is up. The context loaders live at
# app/contexts/<ctx>/lib/<ctx>.rb and require their models/services. Loading
# them after `config/environment` guarantees ApplicationRecord and the Rails
# autoloading setup exist, so the context constants resolve deterministically.
begin
  Dir[Rails.root.join("app/contexts/*/lib/*.rb")].sort.each { |f| require f }
rescue => e
  $stderr.puts "CONTEXT LOAD ERROR: #{e.class}: #{e.message}"
  raise
end

require "rspec/rails"
require "factory_bot_rails"

# Load support files
Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_path = Rails.root.join("spec/fixtures")
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
end
