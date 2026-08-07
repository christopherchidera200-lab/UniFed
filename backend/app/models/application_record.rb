# Base class for all Active Record models in the UniFed Rails app.
# The DDD bounded contexts under app/contexts/* define their own models that
# inherit from this (via ::ApplicationRecord), keeping a single AR base.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
