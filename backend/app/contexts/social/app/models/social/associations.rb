module Social
  class Story < ApplicationRecord
    self.table_name = "social_stories"
    belongs_to :university, class_name: "Academic::University"
    belongs_to :author, class_name: "Identity::User"
    validates :media_url, presence: true
  end

  class ShortVideo < ApplicationRecord
    self.table_name = "social_short_videos"
    belongs_to :university, class_name: "Academic::University"
    belongs_to :author, class_name: "Identity::User"
    validates :media_url, presence: true
  end

  class Poll < ApplicationRecord
    self.table_name = "social_polls"
    belongs_to :university, class_name: "Academic::University"
    belongs_to :author, class_name: "Identity::User"
    has_many :votes, class_name: "Social::PollVote", dependent: :destroy
    validates :question, presence: true
  end

  class PollVote < ApplicationRecord
    self.table_name = "social_poll_votes"
    belongs_to :poll, class_name: "Social::Poll"
    belongs_to :voter, class_name: "Identity::User"
    validates :option_index, presence: true
  end

  class Comment < ApplicationRecord
    self.table_name = "social_comments"
    belongs_to :post, class_name: "Social::Post"
    belongs_to :author, class_name: "Identity::User"
    validates :body, presence: true
  end

  class Reaction < ApplicationRecord
    self.table_name = "social_reactions"
    belongs_to :post, class_name: "Social::Post"
    belongs_to :author, class_name: "Identity::User"
    validates :kind, inclusion: { in: %w[like love laugh angry sad celebrate] }
    validates :author_id, uniqueness: { scope: :post_id }
  end

  # Materialised fan-out of the home feed per user/university (CQRS-lite read
  # model). Populated when a post is created via PostService.
  class FeedEntry < ApplicationRecord
    self.table_name = "social_feed_entries"
    belongs_to :post, class_name: "Social::Post"
    belongs_to :university, class_name: "Academic::University"
    scope :for_university, ->(uni_id) { where(university_id: uni_id).order(rank: :desc) }
  end
end
