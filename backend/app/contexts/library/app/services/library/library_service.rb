module Library
  # Catalogue + loan management for a university library. Students borrow
  # resources; the service tracks availability and returns/overdue transitions.
  class LibraryService
    # Search the catalogue by title/author/type for a university.
    def self.search(university_id, query: nil, type: nil, limit: 20)
      scope = LibraryResource.where(university_id: university_id)
      scope = scope.where(resource_type: type) if type.present?
      scope = scope.where("title ILIKE ? OR author ILIKE ?", "%#{query}%", "%#{query}%") if query.present?
      scope.limit(limit)
    end

    # Borrow a resource for a student (fails if already borrowed).
    def self.borrow!(student:, library_resource:)
      LibraryLoan.create!(student: student, library_resource: library_resource, status: "borrowed")
    end

    # Return a borrowed resource.
    def self.return!(loan:)
      loan.update!(status: "returned", returned_at: Time.current)
      loan
    end

    # Currently-borrowed resources for a student.
    def self.active_loans(student:)
      LibraryLoan.where(student: student, status: "borrowed")
    end
  end
end
