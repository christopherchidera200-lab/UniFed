module Social
  # Read model for the Home feed. Returns the materialised FeedEntry rows for a
  # university (CQRS-lite: writes go through PostService, reads are cheap).
  class FeedService
    PAGE = 20

    def self.home_feed(university_id:, page: 1)
      Social::FeedEntry.for_university(university_id)
        .includes(post: :author)
        .offset((page - 1) * PAGE)
        .limit(PAGE)
        .map(&:post)
    end

    def self.trending(university_id:, limit: 10)
      Social::Post.visible_to(university_id)
        .left_joins(:reactions)
        .group("social_posts.id")
        .order(Arel.sql("COUNT(social_reactions.id) DESC"))
        .limit(limit)
    end
  end
end
