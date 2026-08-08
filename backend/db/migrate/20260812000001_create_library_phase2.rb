# Library (Phase 2 depth): resources + loans.
class CreateLibraryPhase2 < ActiveRecord::Migration[7.1]
  def change
    create_table :library_resources do |t|
      t.references :university, null: false, foreign_key: true
      t.text :title, null: false
      t.text :author
      t.text :isbn
      t.text :resource_type, null: false, default: "book"
      t.timestamps
    end
    add_index :library_resources, %i[university_id resource_type]

    create_table :library_loans do |t|
      t.references :student, null: false, foreign_key: { to_table: :students }
      t.references :library_resource, null: false, foreign_key: true
      t.text :status, null: false, default: "borrowed"
      t.timestamptz :borrowed_at
      t.timestamptz :due_at
      t.timestamptz :returned_at
      t.timestamps
    end
    add_index :library_loans, %i[library_resource_id status]
  end
end
