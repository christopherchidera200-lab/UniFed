# Assessments (Phase 2): component scores (CA/test/exam) per student per
# course offering, rolled into the canonical grade_records row.
class CreateAssessmentPhase2 < ActiveRecord::Migration[7.1]
  def change
    create_table :assessment_records do |t|
      t.references :student, null: false, foreign_key: { to_table: :students }
      t.references :course_offering, null: false, foreign_key: true
      t.text :component, null: false
      t.numeric :score, precision: 5, scale: 2, null: false
      t.numeric :weight, precision: 5, scale: 2, null: false, default: 100
      t.text :recorded_by
      t.timestamps
    end

    add_index :assessment_records, %i[student_id course_offering_id component], unique: true
  end
end
