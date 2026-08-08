module Academic
  # A university event on the academic/ceremonial calendar (convocation,
  # matriculation, SIWES windows, exams, dept events, general).
  # NOTE: the `type` column is a domain enum, NOT Rails STI — disable STI.
  class Event < ::ApplicationRecord
    self.inheritance_column = nil

    belongs_to :university
    belongs_to :faculty, optional: true
    belongs_to :department, optional: true

    validates :title, presence: true
    validates :type, inclusion: {
      in: %w[convocation matriculation siwes exam dept-event general]
    }
    validates :event_start, presence: true
    validate :end_after_start

    scope :upcoming, -> { where("event_start >= ?", Time.current).order(event_start: :asc) }
    scope :in_range, ->(from, to) { where(event_start: from..to).order(event_start: :asc) }
    scope :of_type, ->(t) { where(type: t) }

    private

    def end_after_start
      return if event_end.blank? || event_start.blank?
      errors.add(:event_end, "must be after the start") if event_end < event_start
    end
  end
end
