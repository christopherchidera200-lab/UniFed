require "rails_helper"

RSpec.describe Library::LibraryService, type: :service do
  let(:university) { create(:university) }
  let(:student)    { create(:student, university: university, identity_subject: "s-lib") }

  describe ".search" do
    let!(:book) { create(:library_resource, university: university, title: "Algorithms", author: "Cormen", resource_type: "book") }
    let!(:journal) { create(:library_resource, university: university, title: "Nature", resource_type: "journal") }
    let!(:other) { create(:library_resource, title: "Elsewhere", university: create(:university)) }

    it "scopes to the university" do
      expect(described_class.search(university.id)).to include(book, journal)
      expect(described_class.search(university.id)).not_to include(other)
    end

    it "filters by type" do
      expect(described_class.search(university.id, type: "journal")).to contain_exactly(journal)
    end

    it "filters by query" do
      expect(described_class.search(university.id, query: "algo")).to contain_exactly(book)
    end
  end

  describe ".borrow! / .return!" do
    let(:resource) { create(:library_resource, university: university) }

    it "borrows then returns, tracking availability" do
      loan = described_class.borrow!(student: student, library_resource: resource)
      expect(loan.status).to eq("borrowed")
      returned = described_class.return!(loan: loan)
      expect(returned.status).to eq("returned")
      expect(returned.returned_at).to be_present
    end

    it "prevents double-borrowing the same resource" do
      described_class.borrow!(student: student, library_resource: resource)
      expect do
        described_class.borrow!(student: student, library_resource: resource)
      end.to raise_error(ActiveRecord::RecordInvalid, /already borrowed/)
    end
  end

  describe ".active_loans" do
    it "returns only borrowed loans" do
      r = create(:library_resource, university: university)
      loan = described_class.borrow!(student: student, library_resource: r)
      described_class.return!(loan: loan)
      expect(described_class.active_loans(student: student)).to be_empty
    end
  end
end
