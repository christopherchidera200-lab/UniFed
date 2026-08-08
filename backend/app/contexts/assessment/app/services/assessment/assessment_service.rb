module Assessment
  # Records individual assessment components (CA, test, exam) per student and
  # rolls them up into the canonical GradeRecord (weighted final score) using
  # each component's weight. On publish, recomputes the student's CGPA summary.
  class AssessmentService
    # Record (upsert) one component score for a student in an offering.
    def self.record!(student:, course_offering:, component:, score:, weight: nil, recorded_by: nil)
      rec = AssessmentRecord.find_or_initialize_by(
        student: student, course_offering: course_offering, component: component
      )
      rec.assign_attributes(score: score, weight: weight, recorded_by: recorded_by)
      rec.save!
      rec
    end

    # Roll all components for a student+offering into the final GradeRecord.
    # final = sum(component.score * component.weight) / sum(component.weight)
    def self.rollup!(student:, course_offering:, publish: false, recorded_by: nil)
      components = AssessmentRecord.where(student: student, course_offering: course_offering)
      return nil if components.empty?

      total_weight = components.sum(:weight).to_f
      final_score  = components.sum { |c| c.score.to_f * c.weight } / total_weight

      grade = Records::GradeRecord.find_or_initialize_by(
        student: student, course_offering: course_offering
      )
      grade.assign_attributes(score: final_score.round(2), recorded_by: recorded_by)
      grade.is_published = true if publish
      grade.save!

      Records::AcademicSummaryService.recompute!(student) if publish
      grade
    end

    # All component scores for a student in an offering.
    def self.components_for(student:, course_offering:)
      AssessmentRecord.where(student: student, course_offering: course_offering)
    end
  end
end
