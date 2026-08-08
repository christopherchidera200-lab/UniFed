module Api
  module V1
    # Federation endpoints (ActivityPub). Inbox/outbox are server-to-server;
    # Webfinger is how other instances discover this node's actors.
    class FederationController < BaseController
      skip_before_action :authenticate!, only: %i[inbox outbox webfinger]

      # POST /api/v1/federation/inbox  (signed AP activity from a peer)
      def inbox
        actor = Federation::Actor.find_by(actor_uri: params.dig(:id))
        return render json: { error: "unknown_inbox" }, status: :not_found unless actor
        result, status = Federation::InboxHandler.handle(
          actor: actor, body: JSON.parse(request.body.read), request: request)
        render json: result, status: status
      end

      # GET /api/v1/federation/outbox  (public outbox of an actor)
      def outbox
        actor = Federation::Actor.find_by(actor_uri: params.dig(:id))
        return render json: { error: "unknown_actor" }, status: :not_found unless actor
        activities = actor.activities.order(created_at: :desc).limit(50)
        render json: {
          "@context" => "https://www.w3.org/ns/activitystreams",
          "id" => "#{actor.actor_uri}/outbox",
          "type" => "OrderedCollection",
          "orderedItems" => activities.map(&:to_json_ld)
        }
      end

      # GET /.well-known/webfinger?resource=acct:user@host
      def webfinger
        resource = params[:resource]
        return render json: { error: "bad_resource" }, status: :bad_request unless resource
        actor_uri = Federation::WebfingerService.acct_to_uri(resource)
        actor = Federation::Actor.find_by(actor_uri: actor_uri)
        return render json: { error: "not_found" }, status: :not_found unless actor
        render json: {
          subject: resource,
          links: [
            { rel: "self", type: "application/activity+json", href: actor.actor_uri }
          ]
        }
      end
    end
  end
end
