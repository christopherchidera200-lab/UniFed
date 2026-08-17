import { Megaphone, FileText, FlaskConical, MessagesSquare, ShieldAlert, CalendarDays, Briefcase } from "lucide-react";
import { cn } from "@/lib/cn";
import { FederationBadge } from "./FederationBadge";
import { RoleBadge } from "./RoleBadge";

/**
 * Content-type system — the core "don't repeat the boring Mastodon card" fix.
 * Each type gets its own accent color, icon, and label row so a scrolling feed
 * is scannable without reading every line. Color encodes meaning, not brand.
 */
export type ContentType =
  | "announcement" | "assignment" | "research" | "discussion"
  | "admin" | "event" | "career";

export interface FeedItem {
  id: string;
  type: ContentType;
  authorName: string;
  authorRole?: string | null;
  authorInitials?: string;
  institutionSlug?: string | null;
  institutionName?: string | null;
  title?: string;
  body: string;
  /** Free-form meta chips (e.g. "CSC 301", "3 days left"). */
  chips?: string[];
  /** Optional serif lead (research abstracts / announcements). */
  editorial?: boolean;
  meta?: string; // e.g. timestamp / reply count summary
}

const META: Record<ContentType, { label: string; icon: typeof Megaphone; color: string }> = {
  announcement: { label: "Announcement", icon: Megaphone, color: "ct-announce" },
  assignment:   { label: "Assignment",   icon: FileText,  color: "ct-assignment" },
  research:     { label: "Research",     icon: FlaskConical, color: "ct-research" },
  discussion:   { label: "Discussion",   icon: MessagesSquare, color: "ct-discussion" },
  admin:        { label: "Admin",        icon: ShieldAlert, color: "ct-admin" },
  event:        { label: "Event",        icon: CalendarDays, color: "ct-event" },
  career:       { label: "Career",       icon: Briefcase, color: "ct-career" }
};

function initials(name: string): string {
  return name.split(/\s+/).map((p) => p[0]).slice(0, 2).join("").toUpperCase();
}

export function ContentCard({ item }: { item: FeedItem }) {
  const m = META[item.type];
  const Icon = m.icon;
  return (
    <article className="relative overflow-hidden rounded-md border border-navy-100 dark:border-navy-800 bg-white dark:bg-navy-900 p-4 dark:text-navy-50">
      {/* colored left rail = content type (no reading required) */}
      <span className={cn("absolute left-0 top-3 bottom-3 w-1 rounded-full", `bg-${m.color}`)} />
      <div className={cn("mb-2 flex items-center gap-1.5 text-xs font-bold", `text-${m.color}`)}>
        <Icon size={14} /> {m.label}
        {item.title ? <span className="text-ink dark:text-navy-100 font-semibold"> · {item.title}</span> : null}
      </div>
      <header className="flex items-center gap-2.5">
        <span className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-navy-100 dark:bg-navy-800 text-navy-600 dark:text-navy-200 font-bold text-sm">
          {item.authorInitials ?? initials(item.authorName)}
        </span>
        <div className="min-w-0">
          <div className="flex items-center gap-1.5">
            <span className="truncate font-semibold text-sm">{item.authorName}</span>
            {item.authorRole ? <RoleBadge role={item.authorRole} /> : null}
          </div>
          <div className="flex items-center gap-1.5 text-xs text-ink-subtle">
            {item.meta}
            {item.institutionSlug ? <FederationBadge slug={item.institutionSlug} name={item.institutionName} /> : null}
          </div>
        </div>
      </header>
      <p className={cn(
        "mt-2.5 text-sm text-ink dark:text-navy-100",
        item.editorial && "font-serif"
      )}>
        {item.body}
      </p>
      {item.chips && item.chips.length > 0 ? (
        <div className="mt-2.5 flex flex-wrap gap-1.5">
          {item.chips.map((c) => (
            <span key={c} className={cn("rounded-pill px-2 py-0.5 text-[11px] font-medium", `bg-${m.color}/10`, `text-${m.color}`)}>
              {c}
            </span>
          ))}
        </div>
      ) : null}
    </article>
  );
}
