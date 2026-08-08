module Social
  # Creates posts, fans them out to the university feed, and (when federation is
  # enabled) queues an ActivityPub delivery to peer inboxes.
  class PostService
    def self.create!(author:, body:, visibility: "university", university: nil)
      uni = university || author.university
      post = Social::Post.create!(
        university: uni,
        author: author,
        body: body,
        visibility: visibility,
        federated: false
      )
      fan_out(post)
      post
    end

    def self.fan_out(post)
      Social::FeedEntry.create!(post: post, university: post.university, rank: Time.current.to_f)
    end

    # When federation is enabled, notify peers (queued via Federation::DeliveryService).
    def self.federate(post)
      return unless UniFed::Application.config.x.federation_enabled
      root = Federation::Actor.find_by(actor_type: "university", university_id: post.university_id)
      return unless root
      Federation::DeliveryService.deliver(
        actor: root,
        activity_type: "Create",
        object: { "type" => "Note", "id" => "https://#{URI(UniFed::Application.config.x.oidc_issuer).host}/objects/#{post.id}",
                  "content" => post.body },
        recipients: Federation::Actor.where(actor_type: "university").where.not(id: root.id).pluck(:actor_uri)
      )
    rescue StandardError => e
      Rails.logger.error("federate_post_failed post=#{post.id} err=#{e.message}")
    end
  end
end
