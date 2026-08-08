import { useQuery } from "@tanstack/react-query";
import { unifedApi, getToken, type CourseDTO } from "@/lib/api";
import { RequireAuth } from "@/components/auth/RequireAuth";

/** Course Catalogue browser (Phase 2). Lists courses with optional search. */
export default function CatalogPage() {
  const token = getToken();
  const q = ""; // wire to a search box later
  const courses = useQuery({
    queryKey: ["catalog-courses", q],
    queryFn: () => unifedApi.catalogCourses(token, q ? { q } : {}),
    enabled: Boolean(token)
  });

  return (
    <RequireAuth>
      <section className="space-y-6">
        <header>
          <h1 className="font-display text-2xl font-bold tracking-tight">Course Catalogue</h1>
          <p className="text-ink-muted text-sm">Browse the ADUN course offerings.</p>
        </header>

        <div className="rounded-lg border border-navy-100 dark:border-navy-800 bg-white
                        dark:bg-navy-900/60 shadow-soft overflow-hidden">
          <ul className="divide-y divide-navy-50 dark:divide-navy-800/60">
            {courses.data?.map((c: CourseDTO) => (
              <li key={c.id} className="py-3 px-3 flex items-center justify-between gap-3">
                <div>
                  <div className="font-medium">{c.code}</div>
                  <div className="text-ink-subtle text-xs">{c.title}</div>
                </div>
                <div className="text-right text-xs text-ink-muted">
                  <div>{c.credit_units} units</div>
                  <div>L{c.level} · Sem {c.semester}</div>
                </div>
              </li>
            ))}
          </ul>
          {courses.isLoading && <p className="p-3 text-ink-muted text-sm">Loading…</p>}
          {courses.data?.length === 0 && (
            <p className="p-3 text-ink-muted text-sm">No courses found.</p>
          )}
        </div>
      </section>
    </RequireAuth>
  );
}
