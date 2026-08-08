module Siwes
  # Manages SIWES / internship placements and weekly logs. Students log hours
  # and task summaries; workplace supervisors verify logs. A placement is
  # eligible for completion once all required weekly logs are verified.
  class SiwesService
    REQUIRED_WEEKS = 12 # ITF standard minimum for a session placement (configurable).

    # Create (or return) a placement for a student in a session.
    def self.ensure_placement!(student:, academic_session:, employer_name:, supervisor_name:, supervisor_email:, start_date:, end_date:)
      SiwesPlacement.find_or_initialize_by(student: student, academic_session: academic_session).tap do |p|
        p.assign_attributes(
          employer_name: employer_name, supervisor_name: supervisor_name,
          supervisor_email: supervisor_email, start_date: start_date, end_date: end_date,
          status: p.status || "pending"
        )
        p.save!
      end
    end

    # Student submits a weekly log; supervisor verifies it.
    def self.verify_log!(log_id:, verified_by:)
      log = SiwesLog.find(log_id)
      log.update!(status: "verified", verified_by: verified_by)
      log
    end

    # Completion gate: all required weeks verified for the placement.
    def self.completion_status(placement)
      verified = placement.siwes_logs.where(status: "verified").count
      {
        verified_weeks: verified,
        required_weeks: REQUIRED_WEEKS,
        complete: verified >= REQUIRED_WEEKS,
        status: placement.status
      }
    end
  end
end
