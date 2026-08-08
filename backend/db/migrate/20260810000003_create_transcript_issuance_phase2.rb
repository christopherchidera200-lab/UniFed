# Transcript issuance audit log (Phase 2).
class CreateTranscriptIssuancePhase2 < ActiveRecord::Migration[7.1]
  def change
    create_table :transcript_issuances do |t|
      t.references :student, null: false, foreign_key: { to_table: :students }
      t.text :token_hash, null: false
      t.text :issued_to, null: false
      t.text :purpose
      t.timestamps
    end
    add_index :transcript_issuances, :token_hash, unique: true
  end
end
