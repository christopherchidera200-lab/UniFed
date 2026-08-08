require "rails_helper"

RSpec.describe Siwes::SiwesService, type: :service do
  let(:university) { create(:university) }
  let(:student)    { create(:student, university: university, identity_subject: "s-siwes") }
  let(:session)    { create(:academic_session, university: university) }

  describe ".ensure_placement!" do
    it "creates a placement and is idempotent per session" do
      p1 = described_class.ensure_placement!(
        student: student, academic_session: session, employer_name: "Acme",
        supervisor_name: "Jane", supervisor_email: "jane@acme.com",
        start_date: 60.days.from_now.to_date, end_date: 150.days.from_now.to_date
      )
      expect(p1).to be_persisted
      p2 = described_class.ensure_placement!(
        student: student, academic_session: session, employer_name: "Acme",
        supervisor_name: "Jane", supervisor_email: "jane@acme.com",
        start_date: 60.days.from_now.to_date, end_date: 150.days.from_now.to_date
      )
      expect(p2.id).to eq(p1.id)
    end
  end

  describe ".verify_log!" do
    let(:placement) { create(:siwes_placement, student: student) }

    it "marks a submitted log as verified" do
      log = create(:siwes_log, siwes_placement: placement, status: "submitted")
      verified = described_class.verify_log!(log_id: log.id, verified_by: "supervisor-1")
      expect(verified.status).to eq("verified")
      expect(verified.verified_by).to eq("supervisor-1")
    end
  end

  describe ".completion_status" do
    let(:placement) { create(:siwes_placement, student: student) }

    it "reports not complete until REQUIRED_WEEKS verified logs exist" do
      2.times { |i| create(:siwes_log, siwes_placement: placement, status: "verified", week_number: i + 1) }
      status = described_class.completion_status(placement)
      expect(status[:verified_weeks]).to eq(2)
      expect(status[:required_weeks]).to eq(12)
      expect(status[:complete]).to be false
    end

    it "reports complete when required weeks are verified" do
      12.times { |i| create(:siwes_log, siwes_placement: placement, status: "verified", week_number: i + 1) }
      status = described_class.completion_status(placement)
      expect(status[:complete]).to be true
    end
  end
end
