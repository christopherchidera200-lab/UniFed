require "rails_helper"

RSpec.describe Assessment::AssessmentService, type: :service do
  let(:university) { create(:university) }
  let(:student)    { create(:student, university: university, identity_subject: "s1") }
  let(:course)     { create(:course, credit_units: 3) }
  let(:session)    { create(:academic_session, university: university) }
  let(:offering)   { create(:course_offering, course: course, academic_session: session, semester_number: 1) }

  describe ".record!" do
    it "creates a component and upserts on duplicate (student, offering, component)" do
      r1 = described_class.record!(student: student, course_offering: offering, component: "ca1", score: 70, weight: 30)
      expect(r1).to be_persisted
      r2 = described_class.record!(student: student, course_offering: offering, component: "ca1", score: 85, weight: 30)
      expect(r2.id).to eq(r1.id)
      expect(r2.score).to eq(85)
      expect(Assessment::AssessmentRecord.where(student: student, course_offering: offering, component: "ca1").count).to eq(1)
    end
  end

  describe ".rollup!" do
    it "computes the weighted final score and writes the grade record" do
      # CA1 = 80 @30%, Exam = 70 @70%  => 0.3*80 + 0.7*70 = 73.0
      described_class.record!(student: student, course_offering: offering, component: "ca1", score: 80, weight: 30)
      described_class.record!(student: student, course_offering: offering, component: "exam", score: 70, weight: 70)
      grade = described_class.rollup!(student: student, course_offering: offering)
      expect(grade.score.to_f).to eq(73.0)
      expect(grade.grade_letter).to eq("A") # 73 >= 70 => A
      expect(grade.is_published).to be false
    end

    it "recomputes CGPA summary when published" do
      described_class.record!(student: student, course_offering: offering, component: "exam", score: 85, weight: 100)
      described_class.rollup!(student: student, course_offering: offering, publish: true)
      summary = student.academic_summaries.find_by(academic_session_id: nil)
      expect(summary).to be_present
      expect(summary.cgpa.to_f).to eq(5.0) # 85 -> A (>=70) => 5.0
    end

    it "returns nil when there are no components" do
      expect(described_class.rollup!(student: student, course_offering: offering)).to be_nil
    end
  end
end
