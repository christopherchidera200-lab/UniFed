require "rails_helper"

RSpec.describe Catalog::CourseCatalogService, type: :service do
  let(:university) { create(:university) }
  let(:faculty)    { create(:faculty, university: university) }
  let(:dept)       { create(:department, faculty: faculty) }
  let(:programme)  { create(:programme, department: dept) }
  let!(:course_a)  { create(:course, programme: programme, code: "CYB 301", title: "Network Security", level: 300, semester: 1) }
  let!(:course_b)  { create(:course, programme: programme, code: "CYB 302", title: "Cryptography", level: 300, semester: 2) }
  let!(:course_c)  { create(:course, programme: programme, code: "CYB 401", title: "AI Security", level: 400, semester: 1) }
  let(:session)    { create(:academic_session, university: university) }
  let!(:offering)  { create(:course_offering, course: course_a, academic_session: session, semester_number: 1) }

  describe ".courses" do
    it "lists all courses ordered by level then code" do
      expect(described_class.courses.map(&:code)).to eq(["CYB 301", "CYB 302", "CYB 401"])
    end

    it "filters by level" do
      expect(described_class.courses(level: 300).map(&:code)).to contain_exactly("CYB 301", "CYB 302")
    end

    it "filters by keyword (ILIKE on code/title)" do
      expect(described_class.courses(q: "crypto")).to contain_exactly(course_b)
    end

    it "filters by programme" do
      expect(described_class.courses(programme_id: programme.id)).to contain_exactly(course_a, course_b, course_c)
    end
  end

  describe ".offerings" do
    it "returns offerings for a session with course + lecturer" do
      result = described_class.offerings(academic_session_id: session.id)
      expect(result).to contain_exactly(offering)
      expect(result.first.course.code).to eq("CYB 301")
    end

    it "scopes to a course when given" do
      other = create(:course, programme: programme, code: "CYB 303")
      create(:course_offering, course: other, academic_session: session, semester_number: 1)
      result = described_class.offerings(academic_session_id: session.id, course_id: course_a.id)
      expect(result).to contain_exactly(offering)
    end
  end
end
