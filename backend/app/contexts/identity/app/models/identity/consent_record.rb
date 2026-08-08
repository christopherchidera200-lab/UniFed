module Identity
  # NDPA 2023 consent ledger. Records each consent purpose grant/withdrawal so
  # the platform can prove lawful basis for processing (esp. health/wellbeing).
  # Withdrawal sets withdrawn_at; processing must stop thereafter.
  class ConsentRecord < ApplicationRecord
    self.table_name = "identity_consent_records"
    belongs_to :user, class_name: "Identity::User"

    validates :purpose, presence: true
    validates :purpose, uniqueness: { scope: :user_id }

    scope :active, -> { where(withdrawn_at: nil) }

    def withdrawn?
      withdrawn_at.present?
    end

    def withdraw!
      update!(withdrawn_at: Time.current)
    end
  end
end
