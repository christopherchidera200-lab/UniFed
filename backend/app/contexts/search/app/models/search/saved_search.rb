module Search
  # A user's saved/bookmarked search (Discover tab convenience).
  class SavedSearch < ApplicationRecord
    self.table_name = "search_saved_searches"
    belongs_to :university, class_name: "Academic::University"
    belongs_to :user, class_name: "Identity::User"
    validates :query, presence: true
  end
end
