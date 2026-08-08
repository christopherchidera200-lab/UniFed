module Records
  # Audit log of transcript issuances: who requested, when, and the token hash
  # so a verifier can confirm a transcript was officially issued (tamper-evident).
  class TranscriptIssuance < ::ApplicationRecord
    belongs_to :student, class_name: "Academic::Student"

    validates :token_hash, presence: true, uniqueness: true
    validates :issued_to, presence: true
  end
end
