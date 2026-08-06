module StudentId
  # Audit trail for every verification attempt (privacy-by-design).
  class IdVerificationLog < ApplicationRecord
    belongs_to :digital_student_id, class_name: "StudentId::DigitalStudentId"

    validates :verifier_actor, presence: true
    validates :result, inclusion: { in: [true, false] }
  end
end
