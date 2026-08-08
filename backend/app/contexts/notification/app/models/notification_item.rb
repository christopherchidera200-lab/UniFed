module Notification
  # An in-app notification for a user (x-actor). Read/unread tracked.
  class NotificationItem < ::ApplicationRecord
    self.table_name = "notification_items"
    belongs_to :university, class_name: "Academic::University"
    belongs_to :user, class_name: "Identity::User", optional: true

    validates :channel, inclusion: { in: %w[in_app email sms push] }
    validates :category, inclusion: { in: %w[academic career system siwes library] }
    validates :status, inclusion: { in: %w[unread read archived] }

    scope :unread, -> { where(status: "unread") }
  end
end
