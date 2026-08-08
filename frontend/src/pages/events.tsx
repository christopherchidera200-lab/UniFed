import { useQuery } from "@tanstack/react-query";
import { unifedApi, getToken, type EventDTO } from "@/lib/api";
import { RequireAuth } from "@/components/auth/RequireAuth";

const TYPE_LABEL: Record<string, string> = {
  convocation: "Convocation",
  matriculation: "Matriculation",
  siwes: "SIWES",
  exam: "Exams",
  "dept-event": "Dept Event",
  general: "General"
};

/** Event Calendar (Phase 2): upcoming university events. */
export default function EventsPage() {
  const token = getToken();
  const events = useQuery({
    queryKey: ["events"],
    queryFn: () => unifedApi.events(token),
    enabled: Boolean(token)
  });

  const sorted = [...(events.data ?? [])].sort(
    (a, b) => new Date(a.event_start).getTime() - new Date(b.event_start).getTime()
  );

  return (
    <RequireAuth>
      <section className="space-y-6">
        <header>
          <h1 className="font-display text-2xl font-bold tracking-tight">University Calendar</h1>
          <p className="text-ink-muted text-sm">Upcoming ceremonies, SIWES windows, and exams.</p>
        </header>

        <ol className="relative border-l border-navy-200 dark:border-navy-800 ml-2 space-y-4">
          {sorted.map((e: EventDTO) => (
            <li key={e.id} className="ml-4">
              <span className="absolute -left-1.5 w-3 h-3 rounded-full bg-saffron-500" />
              <time className="text-xs text-ink-muted">
                {new Date(e.event_start).toLocaleDateString(undefined, {
                  day: "numeric", month: "short", year: "numeric"
                })}
              </time>
              <div className="font-medium">{e.title}</div>
              <div className="text-xs text-ink-subtle">{TYPE_LABEL[e.type] ?? e.type}</div>
            </li>
          ))}
          {events.isLoading && <p className="text-ink-muted text-sm">Loading…</p>}
          {sorted.length === 0 && <p className="text-ink-muted text-sm">No upcoming events.</p>}
        </ol>
      </section>
    </RequireAuth>
  );
}
