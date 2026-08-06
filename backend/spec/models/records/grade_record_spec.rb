require "rails_helper"

RSpec.describe Records::GradeRecord, type: :model do
  let(:student) { create(:student) }
  let(:course)  { create(:course) }
  let(:session) { create(:academic_session) }
  let(:offering) { create(:course_offering, course: course, academic_session: session) }

  it "derives NUC grade letter and point from score" do
    g = described_class.new(student: student, course_offering: offering, score: 85)
    g.save!
    expect(g.grade_letter).to eq("A")
    expect(g.grade_point).to eq(5.0)
  end

  it "maps the NUC bands correctly" do
    {
      70 => ["A", 5.0], 60 => ["B", 4.0], 50 => ["C", 3.0],
      45 => ["D", 2.0], 40 => ["E", 1.0], 39 => ["F", 0.0]
    }.each do |score, (letter, point)|
      g = described_class.create!(student: student, course_offering: offering, score: score)
      expect([g.grade_letter, g.grade_point]).to eq([letter, point])
    end
  end

  it "rejects scores out of range" do
    g = described_class.new(student: student, course_offering: offering, score: 101)
    expect(g).not_to be_valid
  end

  it "enforces one record per student/offering pair" do
    described_class.create!(student: student, course_offering: offering, score: 70)
    dup = described_class.new(student: student, course_offering: offering, score: 60)
    expect(dup).not_to be_valid
  end

  it "exposes published records only" do
    published = described_class.create!(student: student, course_offering: offering, score: 70, is_published: true)
    described_class.create!(student: student,
      course_offering: create(:course_offering, course: course, academic_session: session),
      score: 70, is_published: false)
    expect(described_class.published_for(student)).to contain_exactly(published)
  end
end
