module Federation
  # Handles an incoming ActivityPub activity posted to a local actor's inbox.
  # Verifies the HTTP Signature, then dispatches by activity type.
  #
  # F-05: Follow now creates a persisted edge; Delete tombstones the referenced
  #       object (activity or social post) instead of being a no-op.
  # F-06: Replay protection — an activity id seen before is rejected.
  class InboxHandler
    def self.handle(actor:, body:, request:)
      unless SignatureVerifier.verify(request: request, actor_uri: body.dig("actor"))
        return [{ error: "forbidden" }, :forbidden]
      end

      # F-06: reject replays by activity id.
      ap_id = body["id"]
      if ap_id.present? && ProcessedActivity.replayed?(ap_id)
        return [{ error: "replay_detected" }, :unprocessable_entity]
      end

      activity_type = body["type"]
      result, status = case activity_type
                       when "Create" then handle_create(body)
                       when "Follow" then handle_follow(actor, body)
                       when "Delete" then handle_delete(body)
                       else [{ ok: true, ignored: activity_type }, :ok]
                       end

      ProcessedActivity.record!(ap_id, body.dig("actor")) if ap_id.present? && status == :ok
      [result, status]
    rescue ActiveRecord::RecordNotUnique
      # Concurrent/duplicate processing of the same activity id.
      [{ error: "replay_detected" }, :unprocessable_entity]
    end

    def self.handle_create(body)
      object = body["object"]
      if defined?(Social::Post)
        local = resolve_local_actor(body["actor"])
        post = Social::Post.create_from_ap(object, university: local&.university_id)
        [{ ok: true, post_id: post&.id }, :ok]
      else
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

    # F-05: persist the follow edge (auto-accept with audit trail).
    def self.handle_follow(_actor, body)
      follower = body.dig("actor")
      target = body.dig("object")
      followed = Federation::Actor.find_by(actor_uri: target)
      return [{ error: "unknown_target" }, :not_found] unless followed

      follow = Federation::Follow.find_or_create_by!(follower_uri: follower, followed_actor: followed)
      [{ ok: true, accepted: true, follow_id: follow.id }, :ok]
    rescue ActiveRecord::RecordInvalid => e
      [{ error: e.record.errors.full_messages }, :unprocessable_entity]
    end

    # F-05: tombstone the referenced object (activity or social post).
    def self.handle_delete(body)
      object_uri = body.dig("object")
      return [{ error: "missing_object" }, :unprocessable_entity] if object_uri.blank?

      if defined?(Social::Post) && Social::Post.column_names.include?("deleted_at")
        post = Social::Post.find_by(ap_id: object_uri)
        post&.update!(deleted_at: Time.current)
      end
      activity = Federation::Activity.find_by(object_uri: object_uri)
      activity&.update!(deleted_at: Time.current)
      [{ ok: true, deleted: object_uri }, :ok]
    end

    def self.resolve_local_actor(uri)
      Federation::Actor.find_by(actor_uri: uri)
    end
  end
end
