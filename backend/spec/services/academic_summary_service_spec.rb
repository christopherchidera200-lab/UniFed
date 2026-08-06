require "rails_helper"

RSpec.describe Records::AcademicSummaryService, type: :service do
  let(:university) { create(:university) }
  let(:student)    { create(:student, university: university) }
  let(:session)    { create(:academic_session, university: university) }
  let(:programme)  { create(:programme) }

  def grade_for(credit_units, score, semester: 1)
    course    = create(:course, programme: programme, credit_units: credit_units)
    offering  = create(:course_offering, course: course, academic_session: session, semester_number: semester)
    Records::GradeRecord.create!(
      student: student, course_offering: offering, score: score, is_published: true
    )
  end

  it "computes GPA as credit-weighted average of grade points" do
    # 3-credit A (5.0) + 2-credit B (4.0) => (15 + 8)/5 = 4.6
    grade_for(3, 85)
    grade_for(2, 65)
    Records::AcademicSummaryService.recompute!(student)

    summary = student.academic_summaries.find_by(academic_session: session)
    expect(summary.gpa).to be_within(0.01).of(4.6)
    expect(summary.total_credits).to eq(5)
  end

  it "computes cumulative CGPA across sessions" do
    grade_for(3, 85) # 5.0
    Records::AcademicSummaryService.recompute!(student)
    cum = student.academic_summaries.find_by(academic_session_id: nil)
    expect(cum.cgpa).to be_within(0.01).of(5.0)
    expect(cum.class_of_degree).to eq("First Class Honours")
  end

  it "does not include unpublished grades" do
    grade_for(3, 85)
    # unpublished
    course = create(:course, programme: programme, credit_units: 3)
    offering = create(:course_offering, course: course, academic_session: session)
    Records::GradeRecord.create!(student: student, course_offering: offering, score: 10, is_published: false)

    Records::AcademicSummaryService.recompute!(student)
    expect(student.academic_summaries.find_by(academic_session_id: nil).cgpa).to be_within(0.01).of(5.0)
  end
end
