import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { BookOpen, Briefcase, Library, CalendarDays, Sparkles } from "lucide-react";
import { unifedApi, getToken, type EventDTO, type ProfileDTO } from "@/lib/api";
import { RequireAuth } from "@/components/auth/RequireAuth";
import { Card, SectionHeader, IconBadge } from "@/components/ui/Card";
import { cn } from "@/lib/cn";

/** Home dashboard (Phase 2). Bento-style: greeting, stat tiles, shortcut
 *  grid, upcoming events. Mobile-first, navy/saffron, lucide icons. */
export default function HomePage() {
  const token = getToken();

  const profile = useQuery<ProfileDTO>({
    queryKey: ["profile"],
    queryFn: () => unifedApi.profile(token),
    enabled: Boolean(token)
  });
  const courses = useQuery({
    queryKey: ["home-courses"],
    queryFn: () => unifedApi.catalogCourses(),
    enabled: Boolean(token)
  });
  const events = useQuery<EventDTO[]>({
    queryKey: ["home-events"],
    queryFn: () => unifedApi.events(),
    enabled: Boolean(token)
  });

  const displayName = profile.data?.display_name || "there";

  const stats = [
    { label: "Courses", value: courses.data?.length ?? "—" },
    { label: "Events", value: events.data?.length ?? "—" },
    { label: "CGPA", value: "4.2" }
  ];

  const shortcuts = [
    { href: "/catalog", label: "Catalogue", icon: BookOpen, tint: "bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300" },
    { href: "/career", label: "Careers", icon: Briefcase, tint: "bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300" },
    { href: "/library", label: "Library", icon: Library, tint: "bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300" },
    { href: "/events", label: "Events", icon: CalendarDays, tint: "bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300" }
  ];

  return (
    <RequireAuth>
      <div className="space-y-6 animate-fade-up">
        <header className="flex items-center justify-between">
          <div>
            <p className="text-ink-muted text-sm">Welcome back,</p>
            <h1 className="font-display text-2xl font-bold tracking-tight text-ink">
              {displayName}
            </h1>
          </div>
          <IconBadge className="bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300">
            <Sparkles size={20} />
          </IconBadge>
        </header>

        {/* Stat tiles (bento row) */}
        <div className="grid grid-cols-3 gap-3">
          {stats.map((s) => (
            <Card key={s.label} className="text-center">
              <div className="font-display text-2xl font-bold text-navy-500 dark:text-navy-100">
                {s.value}
              </div>
              <div className="text-ink-muted text-xs mt-0.5">{s.label}</div>
            </Card>
          ))}
        </div>

        {/* Shortcut grid */}
        <section className="space-y-3">
          <SectionHeader title="Jump to" eyebrow="Quick access" />
          <div className="grid grid-cols-2 gap-3">
            {shortcuts.map((sc) => {
              const ScIcon = sc.icon;
              return (
                <Link key={sc.href} href={sc.href} className="card card-hover flex items-center gap-3 p-3">
                  <IconBadge className={sc.tint}>
                    <ScIcon size={20} />
                  </IconBadge>
                  <span className="font-medium text-ink">{sc.label}</span>
                </Link>
              );
            })}
          </div>
        </section>

        {/* Upcoming events */}
        <section className="space-y-3">
          <SectionHeader title="Upcoming" eyebrow="What's on" />
          <Card className="divide-y divide-navy-50 dark:divide-navy-800/60 p-0">
            {events.data?.slice(0, 3).map((e: EventDTO) => (
              <div key={e.id} className="flex items-center justify-between px-4 py-3">
                <span className="font-medium text-ink">{e.title}</span>
                <span className={cn(
                  "text-xs px-2 py-0.5 rounded-pill bg-navy-100 dark:bg-navy-800",
                  "text-navy-600 dark:text-navy-200 capitalize"
                )}>
                  {e.type}
                </span>
              </div>
            ))}
            {events.isLoading && <p className="px-4 py-3 text-ink-muted text-sm">Loading…</p>}
            {events.data?.length === 0 && (
              <p className="px-4 py-3 text-ink-muted text-sm">No upcoming events.</p>
            )}
          </Card>
        </section>
      </div>
    </RequireAuth>
  );
}
