require "rails_helper"

# Coverage for the Academic bounded context (was untested per audit).
# The context is a DDD loader for the Academic::* domain models; this spec
# confirms the loader wires the models and that the core aggregates behave.
RSpec.describe "Academic context loader", type: :model do
  # The academic context is loaded at boot (its models are used by factories),
  # so we assert the domain constants are defined and usable.
  it "exposes the Academic::* domain models" do
    %w[
      Academic::University Academic::Faculty Academic::Department
      Academic::Programme Academic::Course Academic::AcademicSession
      Academic::Semester Academic::Lecturer Academic::Student
      Academic::StudentEnrollment Academic::CourseOffering Academic::Event
    ].each do |const|
      expect { const.constantize }.not_to raise_error
    end
  end
end

RSpec.describe Academic::Student, type: :model do
  let(:university) { create(:university) }

  it "belongs to a university and is unique on matric_no within a university" do
    s1 = create(:student, university: university, matric_no: "ADUN/FS/CYB/23/001")
    dup = build(:student, university: university, matric_no: s1.matric_no)
    expect(dup).not_to be_valid
    expect(dup.errors[:matric_no]).to be_present
  end

  it "persists with required academic attributes" do
    student = create(:student, university: university, current_level: 400, status: "active")
    expect(student).to be_persisted
    expect(student.current_level).to eq(400)
  end
end

RSpec.describe Academic::CourseOffering, type: :model do
  let(:university) { create(:university) }
  let(:course) { create(:course) }
  let(:session) { create(:academic_session, university: university) }
  let(:lecturer) { create(:lecturer, university: university) }

  it "links a course to a session + lecturer" do
    offering = create(:course_offering,
                       course: course, academic_session: session, lecturer: lecturer, semester_number: 2)
    expect(offering.course).to eq(course)
    expect(offering.academic_session).to eq(session)
    expect(offering.lecturer).to eq(lecturer)
  end
end
