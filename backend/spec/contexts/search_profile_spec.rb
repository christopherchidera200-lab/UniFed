require "rails_helper"

RSpec.describe Search::QueryService, type: :service do
  let(:university) { create(:university) }
  let!(:author) { create(:identity_user, university: university, skip_password: true, email: "alice.cyber@adun.edu.ng") }
  let!(:course) { create(:course, title: "Cyber Security Fundamentals") }

  it "finds users and courses by substring" do
    results = Search::QueryService.search(query: "cyber", university_id: university.id, categories: %w[users courses])
    expect(results["users"].map(&:email)).to include("alice.cyber@adun.edu.ng")
    expect(results["courses"].map(&:title)).to include("Cyber Security Fundamentals")
  end

  it "returns empty for categories not yet implemented" do
    results = Search::QueryService.search(query: "x", university_id: university.id, categories: %w[jobs scholarships])
    expect(results["jobs"]).to eq([])
    expect(results["scholarships"]).to eq([])
  end
end

RSpec.describe Search::SavedSearch, type: :model do
  it "requires a query" do
    expect(build(:search_saved_search, query: nil)).not_to be_valid
  end
end

RSpec.describe Profile::Profile, type: :model do
  let(:user) { create(:identity_user, skip_password: true) }

  it "is unique per user and validates skill array" do
    p = create(:profile_profile, user: user)
    expect(p).to be_persisted
    dup = build(:profile_profile, user: user)
    expect(dup).not_to be_valid
  end

  it "rejects non-array skills" do
    p = build(:profile_profile, user: user, skills: "not-an-array")
    expect(p).not_to be_valid
  end
end

RSpec.describe Profile::ProfileService, type: :service do
  let(:user) { create(:identity_user, skip_password: true) }

  it "composes a profile view and updates fields" do
    view = Profile::ProfileService.for_user(user)
    expect(view[:email]).to eq(user.email)
    expect(view[:skills]).to eq([])

    updated = Profile::ProfileService.update(user, { bio: "hi", skills: ["Go"] })
    expect(updated[:bio]).to eq("hi")
    expect(updated[:skills]).to eq(["Go"])
  end
end
