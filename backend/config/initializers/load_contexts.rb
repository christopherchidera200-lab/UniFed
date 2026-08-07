# Load the DDD bounded-context namespaces (Academic::, Records::, StudentId::)
# explicitly. Initializers run after the Rails framework is loaded, but the
# context model files inherit from ::ApplicationRecord, which must be defined
# first. We require the base class explicitly, then the per-context loaders
# (app/contexts/<ctx>/lib/<ctx>.rb), which require their models/services.
# Zeitwerk ignores app/contexts (set in config/application.rb) so these
# explicit requires own those constants.
require Rails.root.join("app/models/application_record")
Dir[Rails.root.join("app/contexts/*/lib/*.rb")].sort.each { |f| require f }

