import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { unifedApi, getToken } from "@/lib/api";
import { RequireAuth } from "@/components/auth/RequireAuth";

/** Home dashboard (Phase 2). Greeting + quick stats + shortcuts to the
 *  surfaces the student actually uses. Mobile-first, token-aligned. */
export default function HomePage() {
  const token = getToken();

  // Lightweight live signals (best-effort; degrade gracefully if offline).
  const courses = useQuery({
    queryKey: ["home-courses"],
    queryFn: () => unifedApi.catalogCourses(token),
    enabled: Boolean(token)
  });
  const events = useQuery({
    queryKey: ["home-events"],
    queryFn: () => unifedApi.events(token),
    enabled: Boolean(token)
  });

  const stats = [
    { label: "Courses", value: courses.data?.length ?? "—" },
    { label: "Events", value: events.data?.length ?? "—" },
    { label: "CGPA", value: "4.2" }
  ];

  const shortcuts = [
    { href: "/catalog", label: "Catalogue", glyph: "📚", tint: "bg-navy-100 dark:bg-navy-800" },
    { href: "/career", label: "Careers", glyph: "💼", tint: "bg-saffron-100 dark:bg-saffron-900/40" },
    { href: "/library", label: "Library", glyph: "📖", tint: "bg-navy-100 dark:bg-navy-800" },
    { href: "/events", label: "Events", glyph: "📅", tint: "bg-saffron-100 dark:bg-saffron-900/40" }
  ];

  return (
    <RequireAuth>
      <section className="space-y-6">
        <header>
          <p className="text-ink-muted text-sm">Welcome back,</p>
          <h1 className="font-display text-2xl font-bold tracking-tight">ADUN Student</h1>
        </header>

        {/* Quick stats */}
        <div className="grid grid-cols-3 gap-3">
          {stats.map((s) => (
            <div key={s.label}
                 className="rounded-lg border border-navy-100 dark:border-navy-800 bg-white
                            dark:bg-navy-900/60 shadow-soft p-3 text-center">
              <div className="font-display text-xl font-bold text-navy-700 dark:text-navy-200">
                {s.value}
              </div>
              <div className="text-ink-muted text-xs mt-0.5">{s.label}</div>
            </div>
          ))}
        </div>

        {/* Shortcuts */}
        <div>
          <h2 className="font-display text-sm font-semibold text-ink-muted mb-2">Jump to</h2>
          <div className="grid grid-cols-2 gap-3">
            {shortcuts.map((sc) => (
              <Link key={sc.href} href={sc.href}
                    className={`flex items-center gap-3 rounded-lg border border-navy-100
                                dark:border-navy-800 bg-white dark:bg-navy-900/60
                                shadow-soft p-3 hover:shadow-lift transition-shadow`}>
                <span className={`grid place-items-center w-10 h-10 rounded-md ${sc.tint} text-xl`}>
                  {sc.glyph}
                </span>
                <span className="font-medium">{sc.label}</span>
              </Link>
            ))}
          </div>
        </div>

        {/* Upcoming events */}
        <div>
          <h2 className="font-display text-sm font-semibold text-ink-muted mb-2">Upcoming</h2>
          <ul className="divide-y divide-navy-50 dark:divide-navy-800/60 rounded-lg border
                          border-navy-100 dark:border-navy-800 bg-white dark:bg-navy-900/60 shadow-soft">
            {events.data?.slice(0, 3).map((e) => (
              <li key={e.id} className="py-3 px-3 flex items-center justify-between">
                <div className="font-medium">{e.title}</div>
                <span className="text-xs px-2 py-0.5 rounded-pill bg-navy-100 dark:bg-navy-800
                                 text-navy-600 dark:text-navy-200 capitalize">{e.type}</span>
              </li>
            ))}
            {events.isLoading && <li className="p-3 text-ink-muted text-sm">Loading…</li>}
            {events.data?.length === 0 && (
              <li className="p-3 text-ink-muted text-sm">No upcoming events.</li>
            )}
          </ul>
        </div>
      </section>
    </RequireAuth>
  );
}
