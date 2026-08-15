require "rails_helper"

RSpec.describe Lms::Assignment, type: :model do
  let(:university) { create(:university) }
  let(:offering) { create(:course_offering) }
  let(:lecturer) { offering.lecturer }

  it "is valid with a title and offering" do
    a = described_class.new(course_offering: offering, lecturer: lecturer, title: "Essay 1")
    expect(a).to be_valid
  end

  it "requires a title" do
    a = described_class.new(course_offering: offering, lecturer: lecturer, title: nil)
    expect(a).not_to be_valid
    expect(a.errors[:title]).to be_present
  end

  it "is published by default false" do
    a = described_class.create!(course_offering: offering, lecturer: lecturer, title: "T")
    expect(a.published).to be_falsey
  end
end

RSpec.describe Lms::Submission, type: :model do
  let(:assignment) { create(:lms_assignment) }
  let(:student) { create(:student, university: create(:university)) }

  it "is valid when submitted" do
    s = described_class.new(assignment: assignment, student: student, status: "submitted", submitted_at: Time.current)
    expect(s).to be_valid
  end

  it "rejects an unknown status" do
    s = described_class.new(assignment: assignment, student: student, status: "weird")
    expect(s).not_to be_valid
  end

  it "prevents duplicate submission per student+assignment" do
    described_class.create!(assignment: assignment, student: student, status: "submitted")
    dup = described_class.new(assignment: assignment, student: student, status: "submitted")
    expect(dup).not_to be_valid
  end
end
