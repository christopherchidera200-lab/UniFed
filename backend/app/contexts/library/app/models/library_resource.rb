module Library
  # A catalogued resource (book, journal, past question, ebook) at a university.
  class LibraryResource < ::ApplicationRecord
    belongs_to :university, class_name: "Academic::University"
    has_many :library_loans, dependent: :destroy

    validates :title, presence: true
    validates :resource_type, inclusion: { in: %w[book journal past_question ebook] }
  end
end
