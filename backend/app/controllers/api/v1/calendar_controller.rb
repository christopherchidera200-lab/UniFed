module Api
  module V1
    # Event Calendar endpoints (Phase 2) over the existing events table.
    class CalendarController < BaseController
      skip_before_action :authenticate!, only: %i[events]

      # GET /api/v1/calendar/events?from=&to=&type=  (public browse; scoped to node university)
      def events
        university = node_university
        return render_unauthorized("node_not_configured") unless university

        events = if params[:from].present? && params[:to].present?
          Calendar::CalendarService.in_range(
            university.id, parse_date(params[:from]), parse_date(params[:to]), type: params[:type]
          )
        else
          Calendar::CalendarService.upcoming(university.id, type: params[:type])
        end

        render json: events.map { |e|
          {
            id: e.id, title: e.title, type: e.type,
            event_start: e.event_start, event_end: e.event_end,
            faculty_id: e.faculty_id, department_id: e.department_id
          }
        }
      end

      private

      def parse_date(value)
        Date.parse(value.to_s)
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
