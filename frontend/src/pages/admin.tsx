import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { ShieldCheck, Users, Search, BookOpen, MapPin, FileText } from "lucide-react";
import { unifedApi, getToken } from "@/lib/api";
import { SectionHeader, Card, IconBadge } from "@/components/ui/Card";
import { RequireAuth } from "@/components/auth/RequireAuth";

/** Administration portal (Phase 3). RBAC-gated: admin:users. */
export default function AdminPage() {
  const token = getToken();
  const [q, setQ] = useState("");
  const stats = useQuery({
    queryKey: ["admin-stats"],
    queryFn: () => unifedApi.adminStats(token),
    enabled: Boolean(token)
  });
  const users = useQuery({
    queryKey: ["admin-users", q],
    queryFn: () => unifedApi.adminUsers(token, q ? { q } : {}),
    enabled: Boolean(token)
  });

  const tiles = [
    { label: "Users", value: stats.data?.users, icon: Users, tint: "bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300" },
    { label: "Roles", value: stats.data?.roles, icon: ShieldCheck, tint: "bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300" },
    { label: "Research groups", value: stats.data?.research_groups, icon: BookOpen, tint: "bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300" },
    { label: "Campus places", value: stats.data?.campus_places, icon: MapPin, tint: "bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300" },
    { label: "Assignments", value: stats.data?.assignments, icon: FileText, tint: "bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300" }
  ];

  return (
    <RequireAuth>
      <div className="space-y-6">
        <SectionHeader title="Administration" eyebrow="Node administration" />

        <div className="grid grid-cols-3 gap-3">
          {tiles.map((t) => {
            const TIcon = t.icon;
            return (
              <Card key={t.label} className="text-center">
                <IconBadge className={"mx-auto mb-1 " + t.tint}>
                  <TIcon size={16} />
                </IconBadge>
                <div className="font-display text-xl font-bold text-navy-500 dark:text-navy-100">
                  {t.value ?? "—"}
                </div>
                <div className="text-ink-muted text-[11px] mt-0.5">{t.label}</div>
              </Card>
            );
          })}
        </div>

        <div className="relative">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-subtle" />
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search users by name, email, username…"
            className="w-full rounded-xl border border-navy-100 dark:border-navy-800 bg-white dark:bg-navy-950 pl-9 pr-3 py-2.5 text-sm text-ink outline-none focus:border-saffron-400 focus:ring-2 focus:ring-saffron-200 dark:focus:ring-saffron-500/30"
          />
        </div>

        <Card className="divide-y divide-navy-50 dark:divide-navy-800/60 p-0">
          {users.data?.users.map((u) => (
            <div key={u.id} className="flex items-center justify-between gap-3 px-4 py-3">
              <div className="min-w-0">
                <div className="font-medium text-ink truncate">{u.display_name || u.email}</div>
                <div className="text-ink-subtle text-xs truncate">{u.email}</div>
              </div>
              <div className="flex flex-col items-end gap-1">
                <span className="text-[11px] px-2 py-0.5 rounded-pill bg-navy-100 dark:bg-navy-800 text-navy-600 dark:text-navy-200 capitalize">
                  {u.actor_type}
                </span>
                {u.roles.length > 0 && (
                  <span className="text-[11px] text-ink-subtle">{u.roles.join(", ")}</span>
                )}
              </div>
            </div>
          ))}
          {users.isLoading && <p className="px-4 py-3 text-ink-muted text-sm">Loading…</p>}
          {users.data?.users.length === 0 && (
            <p className="px-4 py-3 text-ink-muted text-sm">No users found.</p>
          )}
        </Card>

        <p className="text-ink-muted text-xs text-center">
          Administration actions require the <code>admin:users</code> permission.
        </p>
      </div>
    </RequireAuth>
  );
}
