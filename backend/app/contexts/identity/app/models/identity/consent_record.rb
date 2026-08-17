module Identity
  # NDPA 2023 consent ledger. Records each consent purpose grant/withdrawal so
  # the platform can prove lawful basis for processing (esp. health/wellbeing).
  # Withdrawal sets withdrawn_at; processing must stop thereafter.
  class ConsentRecord < ApplicationRecord
    self.table_name = "identity_consent_records"
    belongs_to :user, class_name: "Identity::User"

    validates :purpose, presence: true, uniqueness: { scope: :user_id }
    validates :consent_version, presence: true

    scope :active, -> { where(withdrawn_at: nil) }

    # NDPA audit invariant: a granted consent must carry the timestamp it was
    # granted; a refused/withdrawn one carries none. Enforced here so every
    # write path (API, seeds, factories) keeps the ledger consistent.
    before_save :sync_granted_at

    def withdrawn?
      withdrawn_at.present?
    end

    def withdraw!
      update!(withdrawn_at: Time.current)
    end

    private

    def sync_granted_at
      self.granted_at = granted ? (granted_at.presence || Time.current) : nil
    end
  end
end
