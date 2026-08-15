import Link from "next/link";
import { BookOpen, CalendarDays, Briefcase, MapPin, FlaskConical } from "lucide-react";
import { SectionHeader, IconBadge, Card } from "@/components/ui/Card";

/** Discover hub (Phase 2): entry points to the new browse surfaces.
 *  Keeps the mandated 5-tab bottom nav intact; this is the "Discover" target. */
export default function DiscoverPage() {
  const cards = [
    { href: "/catalog", title: "Course Catalogue", icon: BookOpen, tint: "bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300", desc: "Browse ADUN courses by level, semester, and programme." },
    { href: "/campus", title: "Smart Campus", icon: MapPin, tint: "bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300", desc: "Lecture halls, labs, hostels, shuttle stops — find your way." },
    { href: "/research", title: "Research Hub", icon: FlaskConical, tint: "bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300", desc: "Researcher profiles, labs, and publications." },
    { href: "/events", title: "University Calendar", icon: CalendarDays, tint: "bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300", desc: "Convocation, SIWES windows, and exam periods." },
    { href: "/career", title: "Career Hub", icon: Briefcase, tint: "bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300", desc: "Internships, graduate roles, and gigs — apply or save." }
  ];
  return (
    <div className="space-y-6">
      <SectionHeader title="Discover" eyebrow="Explore what UniFed offers" />
      <div className="space-y-3">
        {cards.map((c) => {
          const CIcon = c.icon;
          return (
            <Link key={c.href} href={c.href} className="card card-hover flex items-center gap-3 p-4">
              <IconBadge className={c.tint}>
                <CIcon size={20} />
              </IconBadge>
              <div>
                <div className="font-medium text-ink">{c.title}</div>
                <div className="text-ink-subtle text-sm">{c.desc}</div>
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
