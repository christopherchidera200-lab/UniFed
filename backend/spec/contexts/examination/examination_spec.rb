require "rails_helper"

RSpec.describe Examination::ExamService, type: :service do
  let(:offering)   { create(:course_offering) }
  let(:university) { offering.course.programme.department.faculty.university }

  describe ".schedule!" do
    it "creates an exam sitting" do
      exam = described_class.schedule!(
        university: university, course_offering: offering, exam_type: "exam",
        starts_at: 30.days.from_now, ends_at: 30.days.from_now + 2.hours,
        venue: "Hall A", invigilator: "Dr. X"
      )
      expect(exam).to be_persisted
      expect(exam.venue).to eq("Hall A")
    end

    it "rejects an exam ending before it starts" do
      expect do
        described_class.schedule!(
          university: university, course_offering: offering, exam_type: "exam",
          starts_at: 30.days.from_now, ends_at: 30.days.from_now - 1.hour
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe ".upcoming" do
    it "returns future exams scoped to the university" do
      future = described_class.schedule!(
        university: university, course_offering: offering, exam_type: "exam",
        starts_at: 10.days.from_now, ends_at: 10.days.from_now + 2.hours
      )
      other_uni = create(:course_offering).course.programme.department.faculty.university
      described_class.schedule!(
        university: other_uni, course_offering: create(:course_offering), exam_type: "exam",
        starts_at: 10.days.from_now, ends_at: 10.days.from_now + 2.hours
      )
      expect(described_class.upcoming(university.id)).to contain_exactly(future)
    end
  end
end
