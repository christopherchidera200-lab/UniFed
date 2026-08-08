module Notification
  # Creates and queries user notifications. Kept lightweight (no delivery
  # worker yet — M2 wires email/push via Sidekiq). The service is the single
  # write path so future fan-out (email/sms) slots in cleanly.
  class NotificationService
    def self.notify!(university:, user: nil, category:, title:, body: nil, channel: "in_app")
      NotificationItem.create!(
        university: university, user: user, category: category,
        title: title, body: body, channel: channel, status: "unread"
      )
    end

    def self.unread_for(user:)
      return NotificationItem.none if user.nil?
      NotificationItem.where(user: user, status: "unread").order(created_at: :desc)
    end

    def self.mark_read!(id:)
      item = NotificationItem.find_by(id: id)
      item&.update!(status: "read")
      item
    end

    def self.count_unread(user:)
      unread_for(user: user).count
    end
  end
end
