module Api
  module V1
    # Social feed + posting (Phase 1, Home tab backend).
    class FeedController < BaseController
      before_action :authenticate!

      # GET /api/v1/feed  -> home feed for the user's university
      def index
        page = (params[:page] || 1).to_i
        posts = Social::FeedService.home_feed(current_university.id, page: page)
        render json: posts.map { |p| post_json(p) }
      end

      # POST /api/v1/posts  {body, visibility?}
      def create
        post = Social::PostService.create!(
          author: current_user,
          body: params.dig(:body),
          visibility: params.dig(:visibility) || "university"
        )
        Social::PostService.federate(post)
        render json: post_json(post), status: :created
      end

      # POST /api/v1/posts/:id/react  {kind}
      def react
        post = Social::Post.find_by(id: params[:id], university: current_university)
        return render json: { error: "not_found" }, status: :not_found unless post
        reaction = post.reactions.find_or_initialize_by(author: current_user)
        reaction.kind = params.dig(:kind) || "like"
        reaction.save!
        render json: { ok: true, reactions: post.reactions.count }, status: :ok
      end

      # POST /api/v1/posts/:id/comments  {body}
      def comment
        post = Social::Post.find_by(id: params[:id], university: current_university)
        return render json: { error: "not_found" }, status: :not_found unless post
        comment = post.comments.create!(author: current_user, body: params.dig(:body))
        render json: { id: comment.id, body: comment.body }, status: :created
      end

      private

      def post_json(p)
        {
          id: p.id, body: p.body, visibility: p.visibility, federated: p.federated,
          author_id: p.author_id, created_at: p.created_at,
          reactions_count: p.reactions.count, comments_count: p.comments.count
        }
      end
    end
  end
end
