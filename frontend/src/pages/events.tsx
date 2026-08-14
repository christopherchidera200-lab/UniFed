import { useQuery } from "@tanstack/react-query";
import { CalendarDays } from "lucide-react";
import { unifedApi, getToken, type EventDTO } from "@/lib/api";
import { SectionHeader, IconBadge, Card } from "@/components/ui/Card";

const TYPE_LABEL: Record<string, string> = {
  convocation: "Convocation",
  matriculation: "Matriculation",
  siwes: "SIWES",
  exam: "Exams",
  "dept-event": "Dept Event",
  general: "General"
};

/** Event Calendar (Phase 2): upcoming university events as a timeline. */
export default function EventsPage() {
  const token = getToken();
  const events = useQuery<EventDTO[]>({
    queryKey: ["events"],
    queryFn: () => unifedApi.events(token),
    enabled: Boolean(token)
  });

  const sorted = [...(events.data ?? [])].sort(
    (a, b) => new Date(a.event_start).getTime() - new Date(b.event_start).getTime()
  );

  return (
    <>
      <div className="space-y-6">
        <SectionHeader title="University Calendar" eyebrow="Ceremonies, SIWES & exams" />
        <Card>
          <ol className="relative border-l border-navy-200 dark:border-navy-800 ml-2 space-y-4">
            {sorted.map((e: EventDTO) => (
              <li key={e.id} className="ml-4">
                <span className="absolute -left-1.5 w-3 h-3 rounded-full bg-saffron-500" />
                <time className="text-xs text-ink-muted">
                  {new Date(e.event_start).toLocaleDateString(undefined, {
                    day: "numeric", month: "short", year: "numeric"
                  })}
                </time>
                <div className="font-medium text-ink">{e.title}</div>
                <div className="text-xs text-ink-subtle">{TYPE_LABEL[e.type] ?? e.type}</div>
              </li>
            ))}
            {events.isLoading && <p className="text-ink-muted text-sm">Loading…</p>}
            {sorted.length === 0 && <p className="text-ink-muted text-sm">No upcoming events.</p>}
          </ol>
        </Card>
      </div>
    </>
  );
}
