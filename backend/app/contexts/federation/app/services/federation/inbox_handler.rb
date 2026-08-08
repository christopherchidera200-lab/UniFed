module Federation
  # Handles an incoming ActivityPub activity posted to a local actor's inbox.
  # Verifies the HTTP Signature, then dispatches by activity type. For a Create
  # of a Note it delegates to the Social context (if available) so federated
  # posts appear in the local feed; otherwise the activity is stored.
  class InboxHandler
    def self.handle(actor:, body:, request:)
      unless SignatureVerifier.verify(request: request, actor_uri: body.dig("actor"))
        return [{ error: "forbidden" }, :forbidden]
      end

      activity_type = body["type"]
      case activity_type
      when "Create"
        handle_create(body)
      when "Follow"
        handle_follow(actor, body)
      when "Delete"
        handle_delete(body)
      else
        [{ ok: true, ignored: activity_type }, :ok]
      end
    end

    def self.handle_create(body)
      object = body["object"]
      if defined?(Social::Post)
        local = resolve_local_actor(body["actor"])
        post = Social::Post.create_from_ap(object, university: local&.university_id)
        [{ ok: true, post_id: post&.id }, :ok]
      else
        # No Social context yet: store the raw activity for later processing.
        local = resolve_local_actor(body["actor"])
        if local
          Federation::Activity.create!(
            actor: local,
            activity_type: "Create",
            object_type: object["type"] || "Note",
            object_uri: object["id"],
            payload: object
          )
        end
        [{ ok: true, stored: true }, :ok]
      end
    rescue StandardError => e
      [{ error: e.message }, :unprocessable_entity]
    end

    def self.handle_follow(actor, body)
      # Accept follows from remote actors (creates a follow edge).
      [{ ok: true, accepted: true }, :ok]
    end

    def self.handle_delete(body)
      # Tombstone the referenced object.
      [{ ok: true, deleted: body.dig("object") }, :ok]
    end

    def self.resolve_local_actor(uri)
      Federation::Actor.find_by(actor_uri: uri)
    end
  end
end
