require "rails_helper"

RSpec.describe Campus::Place, type: :model do
  let(:university) { create(:university) }
  let(:campus) { create(:campus_campus, university: university) }

  it "is valid with required attributes" do
    place = described_class.new(university: university, campus: campus,
                                name: "TET Lecture Hall", kind: "lecture_hall",
                                lat: 6.5244, lng: 3.3792)
    expect(place).to be_valid
  end

  it "rejects an unknown kind" do
    place = described_class.new(university: university, campus: campus,
                                name: "X", kind: "spaceship")
    expect(place).not_to be_valid
    expect(place.errors[:kind]).to be_present
  end

  it "computes haversine distance to a point (no PostGIS dependency)" do
    place = create(:campus_place, university: university, campus: campus,
                   lat: 6.5244, lng: 3.3792)
    # ~0 km to itself
    expect(place.distance_to(6.5244, 3.3792)).to be < 0.1
    # ~12,558 km to San Francisco (great-circle)
    expect(place.distance_to(37.7749, -122.4194)).to be_between(12_000, 13_000)
  end
end

RSpec.describe Campus::Campus, type: :model do
  it "requires a name" do
    expect(described_class.new(university: create(:university))).not_to be_valid
  end
end

RSpec.describe Campus::CampusService, type: :service do
  let(:university) { create(:university) }
  let(:campus) { create(:campus_campus, university: university) }

  it "lists places by university and filters by kind" do
    create(:campus_place, university: university, campus: campus, kind: "library", name: "Main")
    create(:campus_place, university: university, campus: campus, kind: "cafeteria", name: "Cafe")
    other = create(:university)
    create(:campus_place, university: other, campus: create(:campus_campus, university: other), kind: "library", name: "Elsewhere")

    expect(Campus::CampusService.list(university: university).count).to eq(2)
    expect(Campus::CampusService.list(university: university, kind: "library").count).to eq(1)
  end

  it "returns nearby places sorted by distance within radius" do
    near = create(:campus_place, university: university, campus: campus,
                  lat: 6.5244, lng: 3.3792, name: "Near")
    far = create(:campus_place, university: university, campus: campus,
                 lat: 6.6000, lng: 3.3792, name: "Far")
    results = Campus::CampusService.near(university: university, lat: 6.5244, lng: 3.3792, radius_km: 5)
    expect(results.map(&:name)).to eq(["Near"])
    expect(results).not_to include(far)
  end
end
