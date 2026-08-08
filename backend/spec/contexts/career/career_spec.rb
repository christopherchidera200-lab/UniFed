require "rails_helper"

RSpec.describe Career::CareerService, type: :service do
  let(:university) { create(:university) }
  let(:employer)   { create(:employer_profile, university: university) }
  let(:student)    { create(:student, university: university, current_level: 300, identity_subject: "sub-123") }
  let!(:open_job)  { create(:career_opportunity, employer_profile: employer, title: "Backend Engineer", employment_type: "full_time", status: "open") }
  let!(:closed_job){ create(:career_opportunity, employer_profile: employer, title: "Old Role", status: "closed") }
  let!(:intern_job){ create(:career_opportunity, employer_profile: employer, title: "Intern", employment_type: "internship", min_level: 200, status: "open") }

  describe ".search" do
    it "returns only open opportunities" do
      results = described_class.search
      expect(results).to include(open_job, intern_job)
      expect(results).not_to include(closed_job)
    end

    it "filters by employment_type and keyword (ILIKE)" do
      expect(described_class.search(employment_type: "internship")).to contain_exactly(intern_job)
      expect(described_class.search(q: "backend")).to contain_exactly(open_job)
    end

    it "filters by minimum level" do
      expect(described_class.search(level: 300)).to include(open_job, intern_job)
      # A level-100 student is below the intern's min_level of 200
      expect(described_class.search(level: 100)).to contain_exactly(open_job)
    end
  end

  describe ".apply!" do
    it "creates an application and is idempotent" do
      app1 = described_class.apply!(student: student, opportunity: open_job)
      expect(app1).to be_persisted
      expect(app1.status).to eq("submitted")
      app2 = described_class.apply!(student: student, opportunity: open_job)
      expect(app2.id).to eq(app1.id)
      expect(student.career_applications.count).to eq(1)
    end
  end

  describe ".toggle_save!" do
    it "saves then unsaves a job" do
      expect(described_class.toggle_save!(student: student, opportunity: open_job)).to eq({ saved: true })
      expect(described_class.toggle_save!(student: student, opportunity: open_job)).to eq({ saved: false })
      expect(student.saved_jobs.count).to eq(0)
    end
  end

  describe ".recommend_for" do
    it "recommends open jobs at or below the student's level" do
      recs = described_class.recommend_for(student)
      expect(recs).to include(open_job)
      expect(recs).not_to include(closed_job)
    end

    it "returns none for a nil student" do
      expect(described_class.recommend_for(nil)).to be_none
    end
  end
end
