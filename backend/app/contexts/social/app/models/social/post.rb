module Social
  # A post in the unified feed. Optionally federated (ap_id set when the post
  # arrived via ActivityPub). Visibility controls the audience.
  class Post < ApplicationRecord
    self.table_name = "social_posts"

    belongs_to :university, class_name: "Academic::University"
    belongs_to :author, class_name: "Identity::User", optional: true
    has_many :comments, class_name: "Social::Comment", dependent: :destroy
    has_many :reactions, class_name: "Social::Reaction", dependent: :destroy
    has_many :feed_entries, class_name: "Social::FeedEntry", dependent: :destroy

    validates :body, presence: true
    validates :visibility, inclusion: { in: %w[public university faculty department followers private] }

    scope :visible_to, lambda { |uni_id|
      where(visibility: %w[public university]).where(university_id: uni_id)
    }

    # Build a local post from a federated AP object (idempotent by ap_id).
    def self.create_from_ap(object, university: nil)
      return nil if object.blank? || object["id"].blank?
      find_or_create_by(ap_id: object["id"]) do |p|
        p.university_id = (university || UniFed::Application.config.x.node_university_id)
        p.body = object["content"].to_s
        p.visibility = "public"
        p.federated = true
      end
    end
  end
end
