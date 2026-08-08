module Library
  # A loan/borrow record for a library resource by a student.
  class LibraryLoan < ::ApplicationRecord
    belongs_to :student, class_name: "Academic::Student"
    belongs_to :library_resource

    validates :status, inclusion: { in: %w[borrowed returned overdue] }
    validate :not_already_borrowed, on: :create

    before_validation :default_dates
    private
    def default_dates
      self.borrowed_at ||= Time.current
      self.due_at ||= 14.days.from_now
    end

    def not_already_borrowed
      return if library_resource.nil?
      if library_resource.library_loans.where(status: "borrowed").exists?
        errors.add(:library_resource, "is already borrowed")
      end
    end
  end
end
