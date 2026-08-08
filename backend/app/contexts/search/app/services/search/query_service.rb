module Search
  # Multi-category search across the platform. Uses PostgreSQL ILIKE (and pg_trgm
  # GIN indexes in production) for structural search; semantic/embedding search
  # is a documented extension point (Phase 1 stub returns structural results).
  class QueryService
    CATEGORIES = %w[users courses posts events clubs jobs scholarships].freeze

    def self.search(query:, university_id:, categories: CATEGORIES, limit: 10)
      q = "%#{query}%"
      results = {}
      categories.each do |cat|
        results[cat] = send("search_#{cat}", q, university_id, limit)
      end
      results
    end

    def self.search_users(q, uni_id, limit)
      Identity::User.where(university_id: uni_id)
        .where("email ILIKE ? OR display_name ILIKE ?", q, q).limit(limit)
        .select(:id, :email, :display_name, :username, :actor_type)
    end

    def self.search_courses(q, uni_id, limit)
      Academic::Course.joins(:programme)
        .where("courses.title ILIKE ? OR courses.code ILIKE ?", q, q).limit(limit)
        .select(:id, :title, :code)
    end

    def self.search_posts(q, uni_id, limit)
      Social::Post.where(university_id: uni_id).where("body ILIKE ?", q).limit(limit).select(:id, :body)
    end

    def self.search_events(q, uni_id, limit)
      ActiveRecord::Base.connection.execute(
        "SELECT id, title, type FROM events WHERE university_id = '#{uni_id}' AND title ILIKE '#{q}' LIMIT #{limit}"
      ).to_a
    end

    # Semantic/embedding search is an extension point; returns structural results
    # until the embeddings pipeline (Phase 1+) is wired.
    def self.search_clubs(_q, _uni_id, _limit) = []
    def self.search_jobs(_q, _uni_id, _limit) = []
    def self.search_scholarships(_q, _uni_id, _limit) = []
  end
end
