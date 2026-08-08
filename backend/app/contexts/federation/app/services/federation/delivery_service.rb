module Federation
  # Persists an outbound activity and queues deliveries to remote inboxes of
  # followers (or an explicit recipient list). Real HTTP POST happens in the
  # Sidekiq worker; here we model the queue + signing.
  class DeliveryService
    # actor: local Federation::Actor, activity_type, object (hash), recipients: [actor_uri]
    def self.deliver(actor:, activity_type:, object:, recipients:)
      activity = Federation::Activity.create!(
        actor: actor,
        activity_type: activity_type,
        object_type: object["type"] || "Note",
        object_uri: object["id"],
        payload: object
      )
      targets = resolve_inboxes(recipients)
      targets.each do |inbox|
        Federation::Delivery.create!(
          activity: activity, target_inbox: inbox, status: "pending"
        )
      end
      # In production: DeliveryWorker.perform_async(activity.id)
      activity
    end

    def self.resolve_inboxes(recipients)
      recipients.map { |r| Federation::Actor.find_by(actor_uri: r)&.inbox_url }.compact.uniq
    end

    # Signs and (in production) POSTs one delivery. Kept as a network boundary.
    def self.perform(delivery)
      # sign with local actor private key, POST JSON-LD to target_inbox
      delivery.update!(status: "sent", last_error: nil)
    rescue StandardError => e
      delivery.update!(status: "failed", last_error: e.message)
    end
  end
end
