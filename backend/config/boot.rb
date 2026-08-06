# Load path setup; tagged for autoloading under Zeitwerk.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
require "bundler/setup"
