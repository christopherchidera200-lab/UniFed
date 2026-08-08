import { useQuery } from "@tanstack/react-query";
import { unifedApi, getToken, type NotificationDTO } from "@/lib/api";
import { RequireAuth } from "@/components/auth/RequireAuth";

/** Notifications inbox (Phase 2 depth). Lists unread notifications. */
export default function NotificationsPage() {
  const token = getToken();
  const notes = useQuery({
    queryKey: ["notifications"],
    queryFn: () => unifedApi.notifications(token),
    enabled: Boolean(token)
  });

  return (
    <RequireAuth>
      <section className="space-y-6">
        <header>
          <h1 className="font-display text-2xl font-bold tracking-tight">Notifications</h1>
          <p className="text-ink-muted text-sm">Updates from your university.</p>
        </header>

        <ul className="space-y-2">
          {notes.data?.map((n: NotificationDTO) => (
            <li key={n.id}
                className="rounded-lg border border-navy-100 dark:border-navy-800 bg-white
                           dark:bg-navy-900/60 shadow-soft p-3">
              <div className="font-medium">{n.title}</div>
              <div className="text-ink-subtle text-xs">{n.body ?? ""}</div>
              <div className="text-ink-muted text-xs mt-1 capitalize">{n.category}</div>
            </li>
          ))}
        </ul>
        {notes.isLoading && <p className="text-ink-muted text-sm">Loading…</p>}
        {notes.data?.length === 0 && (
          <p className="text-ink-muted text-sm">You&apos;re all caught up.</p>
        )}
      </section>
    </RequireAuth>
  );
}
