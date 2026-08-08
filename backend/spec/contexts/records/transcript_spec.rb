require "rails_helper"

RSpec.describe Records::TranscriptService, type: :service do
  let(:university) { create(:university) }
  let(:student)    { create(:student, university: university, identity_subject: "s1") }
  let(:course)     { create(:course, code: "CYB 301", title: "Network Security", credit_units: 3) }
  let(:session)    { create(:academic_session, university: university) }
  let(:offering)   { create(:course_offering, course: course, academic_session: session, semester_number: 1) }

  before do
    # A published grade for the student.
    create(:grade_record, student: student, course_offering: offering, score: 85, is_published: true)
    Records::AcademicSummaryService.recompute!(student)
  end

  describe ".build_payload" do
    it "includes matric, cgpa, and published results" do
      payload = described_class.build_payload(student)
      expect(payload[:matric_no]).to eq(student.matric_no)
      expect(payload[:cgpa]).to eq(5.0) # 85 -> A (>=70) => 5.0
      expect(payload[:results].size).to eq(1)
      expect(payload[:results].first[:code]).to eq("CYB 301")
    end
  end

  describe ".issue_signed / .verify" do
    it "signs a transcript and verifies the round-trip" do
      token = described_class.issue_signed(student)
      expect(token).to be_a(String)

      decoded = described_class.verify(token)
      expect(decoded).to be_a(Hash)
      expect(decoded["matric_no"]).to eq(student.matric_no)
      expect(decoded["cgpa"].to_f).to eq(5.0)
    end

    it "rejects a tampered token" do
      token = described_class.issue_signed(student)
      tampered = token + "x"
      result = described_class.verify(tampered)
      expect(result).to have_key(:error)
    end
  end
end
