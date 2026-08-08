# SIWES / Internship tracking (Phase 2): placements + weekly logs.
class CreateSiwesPhase2 < ActiveRecord::Migration[7.1]
  def change
    create_table :siwes_placements do |t|
      t.references :student, null: false, foreign_key: { to_table: :students }
      t.references :employer_profile, null: true, foreign_key: true
      t.references :academic_session, null: true, foreign_key: true
      t.text :employer_name, null: false
      t.text :supervisor_name
      t.text :supervisor_email
      t.date :start_date
      t.date :end_date
      t.text :status, null: false, default: "pending"
      t.timestamps
    end
    add_index :siwes_placements, %i[student_id academic_session_id], unique: true

    create_table :siwes_logs do |t|
      t.references :siwes_placement, null: false, foreign_key: true
      t.integer :week_number, null: false
      t.numeric :hours, precision: 5, scale: 2, default: 0
      t.text :task_summary
      t.text :status, null: false, default: "draft"
      t.text :verified_by
      t.timestamps
    end
    add_index :siwes_logs, %i[siwes_placement_id week_number], unique: true
  end
end
