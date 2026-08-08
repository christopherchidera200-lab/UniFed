import { useQuery } from "@tanstack/react-query";
import { unifedApi, getToken, type LibraryResourceDTO } from "@/lib/api";
import { RequireAuth } from "@/components/auth/RequireAuth";

/** Library catalogue browser (Phase 2 depth). Lists resources + availability. */
export default function LibraryPage() {
  const token = getToken();
  const resources = useQuery({
    queryKey: ["library-resources"],
    queryFn: () => unifedApi.libraryResources(token),
    enabled: Boolean(token)
  });

  return (
    <RequireAuth>
      <section className="space-y-6">
        <header>
          <h1 className="font-display text-2xl font-bold tracking-tight">Library</h1>
          <p className="text-ink-muted text-sm">Books, journals, and past questions.</p>
        </header>

        <ul className="divide-y divide-navy-50 dark:divide-navy-800/60 rounded-lg border
                        border-navy-100 dark:border-navy-800 bg-white dark:bg-navy-900/60 shadow-soft">
          {resources.data?.map((r: LibraryResourceDTO) => (
            <li key={r.id} className="py-3 px-3 flex items-center justify-between gap-3">
              <div>
                <div className="font-medium">{r.title}</div>
                <div className="text-ink-subtle text-xs">{r.author ?? "—"} · {r.type}</div>
              </div>
              <span className={`text-xs px-2 py-0.5 rounded-pill ${
                r.available ? "bg-green-100 text-green-700" : "bg-navy-100 text-navy-600"
              }`}>
                {r.available ? "Available" : "Borrowed"}
              </span>
            </li>
          ))}
        </ul>
        {resources.isLoading && <p className="text-ink-muted text-sm">Loading…</p>}
        {resources.data?.length === 0 && (
          <p className="text-ink-muted text-sm">No resources found.</p>
        )}
      </section>
    </RequireAuth>
  );
}
