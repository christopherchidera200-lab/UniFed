require "rails_helper"

RSpec.describe Calendar::CalendarService, type: :service do
  let(:university) { create(:university) }
  let!(:future_event) { create(:event, university: university, title: "Convocation", type: "convocation", event_start: 10.days.from_now, event_end: 11.days.from_now) }
  let!(:past_event)   { create(:event, university: university, title: "Old Matric", type: "matriculation", event_start: 5.days.ago, event_end: 4.days.ago) }
  let!(:siwes_event)  { create(:event, university: university, title: "SIWES Window", type: "siwes", event_start: 20.days.from_now, event_end: 50.days.from_now) }

  describe ".upcoming" do
    it "returns only future events ordered by start" do
      result = described_class.upcoming(university.id)
      expect(result).to include(future_event, siwes_event)
      expect(result).not_to include(past_event)
      expect(result.first.event_start).to be <= result.last.event_start
    end

    it "filters by type" do
      expect(described_class.upcoming(university.id, type: "siwes")).to contain_exactly(siwes_event)
    end

    it "scopes to the given university only" do
      other = create(:event, title: "Elsewhere", type: "general", event_start: 2.days.from_now)
      result = described_class.upcoming(university.id)
      expect(result).not_to include(other)
    end
  end

  describe ".in_range" do
    it "returns events whose start falls in the range" do
      from = 15.days.from_now.to_date
      to = 25.days.from_now.to_date
      result = described_class.in_range(university.id, from, to)
      expect(result).to contain_exactly(siwes_event)
    end

    it "returns empty when dates are missing" do
      expect(described_class.in_range(university.id, nil, nil)).to eq([])
    end
  end

  describe ".by_day" do
    it "groups events by date" do
      grouped = described_class.by_day([future_event])
      expect(grouped[future_event.event_start.to_date]).to contain_exactly(future_event)
    end
  end
end
