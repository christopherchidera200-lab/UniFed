class CreateLmsContext < ActiveRecord::Migration[7.1]
  def up
    create_table :lms_assignments, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :course_offering_id, null: false
      t.uuid :lecturer_id, null: false
      t.string :title, null: false
      t.text :description
      t.text :instructions
      t.jsonb :rubric, default: {}
      t.decimal :max_score, precision: 6, scale: 2, default: 100.0
      t.datetime :due_at
      t.boolean :published, default: false
      t.timestamps
    end
    add_foreign_key :lms_assignments, :course_offerings, column: :course_offering_id if table_exists?(:course_offerings)
    add_index :lms_assignments, :course_offering_id
    add_index :lms_assignments, :lecturer_id

    create_table :lms_submissions, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :assignment_id, null: false
      t.uuid :student_id, null: false
      t.text :body
      t.string :attachment_ref
      t.datetime :submitted_at
      t.decimal :score, precision: 6, scale: 2
      t.text :feedback
      t.uuid :graded_by_id
      t.string :status, null: false, default: "draft" # draft | submitted | graded
      t.timestamps
    end
    add_foreign_key :lms_submissions, :lms_assignments, column: :assignment_id
    add_index :lms_submissions, :assignment_id
    add_index :lms_submissions, :student_id
    add_index :lms_submissions, [:assignment_id, :student_id], unique: true
  end

  def down
    drop_table :lms_submissions
    drop_table :lms_assignments
  end
end
