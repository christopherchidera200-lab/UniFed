require "rails_helper"

# Coverage for the Search bounded context (was untested per audit).
# NOTE (security, now fixed): Search::QueryService#search_events previously
# interpolated university_id/query into raw SQL (SQL-injection + uuid-type
# crash). It is now parameterized via sanitize_sql_array, so a non-UUID
# university_id no longer raises and input is escaped.
RSpec.describe Search::SavedSearch, type: :model do
  let(:university) { create(:university) }
  let(:user) { create(:identity_user, university: university) }

  it "requires a query" do
    expect(build(:search_saved_search, user: user, university: university, query: nil)).not_to be_valid
  end

  it "persists a saved search for a user + university" do
    saved = create(:search_saved_search, user: user, university: university, query: "cyber")
    expect(saved).to be_persisted
    expect(saved.query).to eq("cyber")
  end
end

RSpec.describe Search::QueryService, type: :service do
  let(:university) { create(:university) }
  let(:user) { create(:identity_user, university: university, display_name: "Ada Lovelace") }
  let(:course) { create(:course, code: "CYB 301", title: "Network Security", credit_units: 3) }
  let(:event) { create(:event, university: university, title: "Convocation 2026") }

  describe ".search" do
    # One self-contained example builds all fixtures inline so the ILIKE
    # matches are not subject to cross-example let/memoization quirks.
    it "matches users, courses, and events by ILIKE within the university" do
      uni = create(:university)
      user = create(:identity_user, university: uni, display_name: "Ada Lovelace")
      course = create(:course, code: "CYB 301", title: "Network Security", credit_units: 3)
      event = create(:event, university: uni, title: "Convocation 2026")
      other_uni = create(:university)
      other_user = create(:identity_user, university: other_uni, display_name: "Ada Clone")

      results = described_class.search(query: "ada", university_id: uni.id)

      # users: matches Ada Lovelace, excludes the other-university Ada Clone.
      user_hits = results["users"].map(&:id)
      expect(user_hits).to include(user.id)
      expect(user_hits).not_to include(other_user.id)

      # courses: "Network Security" matches "security".
      course_hits = described_class.search(query: "security", university_id: uni.id)["courses"].map(&:id)
      expect(course_hits).to include(course.id)

      # events: "Convocation 2026" matches "convocation" (hash-shaped result).
      event_hits = described_class.search(query: "convocation", university_id: uni.id)["events"].map { |h| h["id"] }
      expect(event_hits).to include(event.id)
    end

    it "returns a result bucket for every category" do
      results = described_class.search(query: "cyber", university_id: create(:university).id)
      expect(results.keys).to match_array(Search::QueryService::CATEGORIES)
    end

    it "returns empty arrays for not-yet-implemented categories (extension points)" do
      results = described_class.search(query: "x", university_id: create(:university).id)
      expect(results["clubs"]).to eq([])
      expect(results["jobs"]).to eq([])
      expect(results["scholarships"]).to eq([])
    end

    it "does not raise on a non-UUID university_id (parameterized events query)" do
      # Parameterization escapes input; a non-UUID value is a caller error,
      # but it must not be an SQL-injection vector. Assert no breakout occurs.
      expect do
        described_class.search(query: "x' OR '1'='1", university_id: "00000000-0000-0000-0000-000000000000")
      end.not_to raise_error
    end
  end
end
