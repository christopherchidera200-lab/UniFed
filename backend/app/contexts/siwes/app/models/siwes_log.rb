module Siwes
  # A weekly log entry from a student's SIWES placement (hours + task summary),
  # confirmed by the workplace supervisor. Drives the placement completion gate.
  class SiwesLog < ::ApplicationRecord
    belongs_to :siwes_placement

    validates :siwes_placement, uniqueness: { scope: :week_number }
    validates :week_number, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 24 }
    validates :hours, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 168 }
    validates :status, inclusion: { in: %w[draft submitted verified] }

    before_validation :default_status
    private
    def default_status
      self.status ||= "draft"
    end
  end
end
