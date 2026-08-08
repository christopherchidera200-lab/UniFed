module Calendar
  # Query service over the university event calendar. The events table is owned
  # by the Academic context; this context provides student/staff-facing views
  # (upcoming, by range, by type) scoped to a university.
  class CalendarService
    # Upcoming events for a university (optionally filtered by type).
    def self.upcoming(university_id, type: nil)
      scope = Academic::Event.where(university_id: university_id).upcoming
      scope = scope.of_type(type) if type.present?
      scope
    end

    # Events within a date range (inclusive), ordered by start.
    def self.in_range(university_id, from, to, type: nil)
      return [] if from.nil? || to.nil?
      scope = Academic::Event.where(university_id: university_id).in_range(from, to)
      scope = scope.of_type(type) if type.present?
      scope
    end

    # Group events by day for calendar rendering.
    def self.by_day(events)
      events.group_by { |e| e.event_start.to_date }
    end
  end
end
