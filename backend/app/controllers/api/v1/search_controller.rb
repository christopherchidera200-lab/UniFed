module Api
  module V1
    # Universal search (Discover tab). Structural search now; semantic is a stub.
    class SearchController < BaseController
      before_action :authenticate!

      # GET /api/v1/search?q=...&categories=users,courses,posts
      def index
        categories = (params[:categories] || "users,courses,posts,events").split(",")
        results = Search::QueryService.search(
          query: params[:q].to_s,
          university_id: current_university.id,
          categories: categories
        )
        render json: results
      end

      # POST /api/v1/search/saved  {query, filters?}
      def save
        saved = Search::SavedSearch.create!(
          university: current_university,
          user: current_user,
          query: params.dig(:query),
          filters: params.dig(:filters) || {}
        )
        render json: { id: saved.id, query: saved.query }, status: :created
      end
    end
  end
end
