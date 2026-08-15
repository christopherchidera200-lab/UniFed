require "rails_helper"

RSpec.describe Research::ResearchProfile, type: :model do
  let(:university) { create(:university) }
  let(:user) { create(:identity_user, university: university) }

  it "is valid with a unique user" do
    p = described_class.new(user: user, university: university, title: "Dr. X")
    expect(p).to be_valid
  end

  it "rejects a bad ORCID" do
    p = described_class.new(user: user, university: university, orcid: "not-a-orcid")
    expect(p).not_to be_valid
    expect(p.errors[:orcid]).to be_present
  end

  it "rejects duplicate user_id" do
    described_class.create!(user: user, university: university, title: "A")
    dup = described_class.new(user: user, university: university, title: "B")
    expect(dup).not_to be_valid
  end
end

RSpec.describe Research::ResearchGroup, type: :model do
  it "is valid with a name" do
    expect(build(:research_group)).to be_valid
  end

  it "requires a name" do
    g = build(:research_group, name: nil)
    expect(g).not_to be_valid
  end
end

RSpec.describe Research::Publication, type: :model do
  let(:university) { create(:university) }
  let(:group) { create(:research_group, university: university) }

  it "requires a group or profile" do
    p = build(:research_publication, group: nil, profile: nil, university: university)
    expect(p).not_to be_valid
  end

  it "is valid with a group" do
    expect(build(:research_publication, group: group, university: university)).to be_valid
  end
end
