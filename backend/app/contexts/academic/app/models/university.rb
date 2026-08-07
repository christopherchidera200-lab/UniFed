module Academic
  # University / institution node. Each deployed instance owns exactly one
  # primary university record (the federation node it represents).
  class University < ::ApplicationRecord
    has_many :faculties, dependent: :destroy
    has_many :academic_sessions, dependent: :destroy
    has_many :lecturers, dependent: :restrict_with_error
    has_many :students, dependent: :restrict_with_error

    validates :slug, presence: true, uniqueness: true
    validates :name, presence: true
    validates :kind, inclusion: { in: %w[federal state private public] }
    validates :country_iso, length: { is: 2 }
    validate  :config_json_is_hash

    # Matric-number pattern is config-driven (ADR-0005 §2), NOT a hardcoded regex.
    # Example config: { "matric_pattern" => "ADUN/{FAC}/{DEPT}/{YEAR}/{SEQ}",
    #                    "faculty_codes" => {"FOS"=>"FS"}, ... }
    def matric_pattern
      config_json.fetch("matric_pattern", "ADUN/{FAC}/{DEPT}/{YEAR}/{SEQ}")
    end

    def valid_matric?(matric_no)
      # Structural validation only; segment vocab confirmed with Registry (⚠️).
      matric_no.to_s.match?(%r{\A[A-Z0-9]+/[^/]+/[^/]+/\d{2}/\d+\z})
    end

    private

    def config_json_is_hash
      errors.add(:config_json, "must be a JSON object") unless config_json.is_a?(Hash)
    end
  end
end
