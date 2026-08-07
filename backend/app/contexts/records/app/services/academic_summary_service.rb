module Records
  # Recomputes GPA (per session) and CGPA (cumulative) for a student and
  # writes the materialized AcademicSummary rows. Called when a grade publishes.
  class AcademicSummaryService
    def self.recompute!(student)
      new(student).call
    end

    def initialize(student)
      @student = student
    end

    def call
      ActiveRecord::Base.transaction do
        per_session_summaries
        cumulative_summary
      end
      @student.academic_summaries.reload
    end

    private

    # GPA per academic session from published grade records.
    def per_session_summaries
      published
        .joins(course_offering: { course: :programme })
        .group("course_offerings.academic_session_id")
        .select(
          "course_offerings.academic_session_id AS sid",
          Arel.sql("SUM(grade_records.grade_point * courses.credit_units) / SUM(courses.credit_units) AS gpa"),
          Arel.sql("SUM(courses.credit_units) AS credits")
        )
        .each do |row|
          upsert_summary(session_id: row.sid, gpa: row.gpa, credits: row.credits)
        end
    end

    # Cumulative CGPA across all sessions.
    def cumulative_summary
      cgpa, credits = published
        .joins(course_offering: { course: :programme })
        .pluck(
          Arel.sql("SUM(grade_records.grade_point * courses.credit_units) / NULLIF(SUM(courses.credit_units), 0)"),
          Arel.sql("SUM(courses.credit_units)")
        )
        .first
      return if cgpa.nil? || credits.nil?
      upsert_summary(session_id: nil, gpa: nil, credits: credits, cgpa: cgpa)
    end

    def published
      Records::GradeRecord.published_for(@student)
    end

    def upsert_summary(session_id:, gpa:, credits:, cgpa: nil)
      summary = Records::AcademicSummary.find_or_initialize_by(
        student: @student, academic_session_id: session_id
      )
      summary.assign_attributes(
        gpa: gpa,
        total_credits: credits || 0,
        cgpa: cgpa || summary.cgpa,
        class_of_degree: cgpa ? Records::AcademicSummary.classify(cgpa) : summary.class_of_degree
      )
      summary.save!
    end
  end
end
