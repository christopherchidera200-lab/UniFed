import { useQuery } from "@tanstack/react-query";
import { Library } from "lucide-react";
import { unifedApi, getToken, type LibraryResourceDTO } from "@/lib/api";
import { RequireAuth } from "@/components/auth/RequireAuth";
import { Card, SectionHeader, IconBadge } from "@/components/ui/Card";
import { cn } from "@/lib/cn";

/** Library catalogue browser (Phase 2 depth). Lists resources + availability. */
export default function LibraryPage() {
  const token = getToken();
  const resources = useQuery<LibraryResourceDTO[]>({
    queryKey: ["library-resources"],
    queryFn: () => unifedApi.libraryResources(token),
    enabled: Boolean(token)
  });

  return (
    <RequireAuth>
      <div className="space-y-6">
        <SectionHeader title="Library" eyebrow="Books, journals & past questions" />
        <Card className="divide-y divide-navy-50 dark:divide-navy-800/60 p-0">
          {resources.data?.map((r: LibraryResourceDTO) => (
            <div key={r.id} className="flex items-center justify-between gap-3 px-4 py-3">
              <div className="flex items-center gap-3">
                <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
                  <Library size={18} />
                </IconBadge>
                <div>
                  <div className="font-medium text-ink">{r.title}</div>
                  <div className="text-ink-subtle text-xs">{r.author ?? "—"} · {r.type}</div>
                </div>
              </div>
              <span className={cn(
                "text-xs px-2 py-0.5 rounded-pill",
                r.available
                  ? "bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-300"
                  : "bg-navy-100 text-navy-600 dark:bg-navy-800 dark:text-navy-200"
              )}>
                {r.available ? "Available" : "Borrowed"}
              </span>
            </div>
          ))}
          {resources.isLoading && <p className="px-4 py-3 text-ink-muted text-sm">Loading…</p>}
          {resources.data?.length === 0 && (
            <p className="px-4 py-3 text-ink-muted text-sm">No resources found.</p>
          )}
        </Card>
      </div>
    </RequireAuth>
  );
}
