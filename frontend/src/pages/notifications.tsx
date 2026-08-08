import { useQuery } from "@tanstack/react-query";
import { Bell } from "lucide-react";
import { unifedApi, getToken, type NotificationDTO } from "@/lib/api";
import { RequireAuth } from "@/components/auth/RequireAuth";
import { Card, SectionHeader, IconBadge } from "@/components/ui/Card";

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
            <Card key={n.id} className="flex items-start gap-3">
              <IconBadge className="bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300">
                <Bell size={18} />
              </IconBadge>
              <div>
                <div className="font-medium text-ink">{n.title}</div>
                <div className="text-ink-subtle text-xs">{n.body ?? ""}</div>
                <div className="text-ink-muted text-xs mt-1 capitalize">{n.category}</div>
              </div>
            </Card>
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
