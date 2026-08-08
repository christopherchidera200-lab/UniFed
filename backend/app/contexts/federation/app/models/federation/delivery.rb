module Federation
  # One outbound delivery of an activity to a remote inbox. Retried by the
  # delivery worker (Sidekiq in production). Tracks status for observability.
  class Delivery < ApplicationRecord
    self.table_name = "federation_deliveries"

    belongs_to :activity, class_name: "Federation::Activity"

    validates :target_inbox, presence: true
    validates :status, inclusion: { in: %w[pending sent failed] }, allow_nil: true

    scope :pending, -> { where(status: "pending") }
  end
end
