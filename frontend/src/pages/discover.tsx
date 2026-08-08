import Link from "next/link";

/** Discover hub (Phase 2): entry points to the new browse surfaces.
 *  Keeps the mandated 5-tab bottom nav intact; this is the "Discover" target. */
export default function DiscoverPage() {
  const cards = [
    { href: "/catalog", title: "Course Catalogue", desc: "Browse ADUN courses by level, semester, and programme." },
    { href: "/events", title: "University Calendar", desc: "Convocation, SIWES windows, and exam periods." },
    { href: "/career", title: "Career Hub", desc: "Internships, graduate roles, and gigs — apply or save." }
  ];
  return (
    <section className="space-y-6">
      <header>
        <h1 className="font-display text-2xl font-bold tracking-tight">Discover</h1>
        <p className="text-ink-muted text-sm">Explore what UniFed offers.</p>
      </header>
      <div className="grid gap-3">
        {cards.map((c) => (
          <Link key={c.href} href={c.href}
                className="block rounded-lg border border-navy-100 dark:border-navy-800 bg-white
                           dark:bg-navy-900/60 shadow-soft p-4 hover:border-saffron-300 transition-colors">
            <div className="font-medium">{c.title}</div>
            <div className="text-ink-subtle text-sm">{c.desc}</div>
          </Link>
        ))}
      </div>
    </section>
  );
}
