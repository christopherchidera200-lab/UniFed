require "rails_helper"

# Coverage for the Profile bounded context (was untested per audit).
RSpec.describe Profile::Profile, type: :model do
  let(:university) { create(:university) }
  let(:user) { create(:identity_user, university: university) }

  it "is unique per user" do
    create(:profile_profile, user: user)
    dup = build(:profile_profile, user: user)
    expect(dup).not_to be_valid
    expect(dup.errors[:user_id]).to be_present
  end

  it "requires skills to be an array" do
    profile = build(:profile_profile, user: user, skills: "not-an-array")
    expect(profile).not_to be_valid
    expect(profile.errors[:skills]).to be_present
  end

  it "requires social_links values to be strings" do
    profile = build(:profile_profile, user: user, social_links: { twitter: 123 })
    expect(profile).not_to be_valid
    expect(profile.errors[:social_links]).to be_present
  end

  it "accepts a well-formed profile" do
    profile = build(:profile_profile, user: user,
                     skills: %w[rails go], social_links: { twitter: "@chidera" })
    expect(profile).to be_valid
  end
end

RSpec.describe Profile::ProfileService, type: :service do
  let(:university) { create(:university) }
  let(:user) { create(:identity_user, university: university, display_name: "Ada") }

  describe ".for_user" do
    it "composes identity + extended profile with safe defaults" do
      create(:profile_profile, user: user, skills: %w[rails], creator: true, social_links: {})
      view = described_class.for_user(user)
      expect(view[:display_name]).to eq("Ada")
      expect(view[:skills]).to eq(%w[rails])
      expect(view[:creator]).to be(true)
      expect(view[:social_links]).to eq({})
    end

    it "initializes an empty profile when none exists" do
      view = described_class.for_user(user)
      expect(view[:skills]).to eq([])
      expect(view[:portfolio]).to eq([])
    end
  end

  describe ".update" do
    it "persists editable attributes and re-composes the view" do
      out = described_class.update(user, bio: "Builder.", skills: %w[go], creator: true)
      expect(out[:bio]).to eq("Builder.")
      expect(out[:creator]).to be(true)
      expect(Profile::Profile.find_by(user: user).skills).to eq(%w[go])
    end
  end
end
