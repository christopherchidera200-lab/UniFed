import { useQuery } from "@tanstack/react-query";
import { unifedApi, getToken, type NotificationDTO } from "@/lib/api";
import { RequireAuth } from "@/components/auth/RequireAuth";
import { SectionHeader } from "@/components/ui/Card";
import { NotificationRow } from "@/components/NotificationRow";

/** Notifications inbox (Phase 2 depth). */
export default function NotificationsPage() {
  const token = getToken();
  const notes = useQuery<NotificationDTO[]>({
    queryKey: ["notifications"],
    queryFn: () => unifedApi.notifications(token),
    enabled: Boolean(token)
  });

  return (
    <RequireAuth>
      <div className="space-y-6">
        <SectionHeader title="Notifications" eyebrow="Updates from your university" />
        <div className="space-y-3">
          {notes.data?.map((n: NotificationDTO) => (
            <NotificationRow
              key={n.id}
              n={{
                id: n.id,
                actorName: (n.title ?? "UniFed").split(" ")[0],
                summary: n.category,
                preview: n.body ?? undefined
              }}
            />
          ))}
        </div>
        {notes.isLoading && <p className="text-ink-muted text-sm">Loading…</p>}
        {notes.data?.length === 0 && (
          <p className="text-ink-muted text-sm">You&apos;re all caught up.</p>
        )}
      </div>
    </RequireAuth>
  );
}
