import { Reply, Star, MoreHorizontal } from "lucide-react";
import { cn } from "@/lib/cn";
import { FederationBadge } from "./FederationBadge";
import { RoleBadge } from "./RoleBadge";

/** Threaded notification row — who acted, what they said, quick actions. */
export interface NotificationLike {
  id: string;
  actorName: string;
  actorRole?: string | null;
  actorInitials?: string;
  institutionSlug?: string | null;
  institutionName?: string | null;
  summary: string; // e.g. "replied to your post"
  preview?: string;
}

export function NotificationRow({
  n, onReply, onSave, className
}: {
  n: NotificationLike;
  onReply?: (id: string) => void;
  onSave?: (id: string) => void;
  className?: string;
}) {
  const initials = (n.actorInitials ?? n.actorName.split(/\s+/).map((p) => p[0]).slice(0, 2).join("").toUpperCase());
  return (
    <div className={cn(
      "flex items-start gap-3 rounded-md border border-navy-50 dark:border-navy-800 bg-white dark:bg-navy-900 p-3",
      className
    )}>
      <span className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-navy-100 dark:bg-navy-800 font-bold text-navy-600 dark:text-navy-200">
        {initials}
      </span>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-1.5 text-sm">
          <span className="font-semibold">{n.actorName}</span>
          {n.actorRole ? <RoleBadge role={n.actorRole} /> : null}
          <span className="text-ink-subtle">{n.summary}</span>
          {n.institutionSlug ? <FederationBadge slug={n.institutionSlug} name={n.institutionName} /> : null}
        </div>
        {n.preview ? <p className="mt-0.5 text-xs text-ink-muted line-clamp-2">{n.preview}</p> : null}
        <div className="mt-1.5 flex items-center gap-4 text-ink-subtle text-xs">
          <button type="button" onClick={() => onReply?.(n.id)} className="flex items-center gap-1 hover:text-navy-600 dark:hover:text-navy-200">
            <Reply size={13} /> Reply
          </button>
          <button type="button" onClick={() => onSave?.(n.id)} className="flex items-center gap-1 hover:text-navy-600 dark:hover:text-navy-200">
            <Star size={13} /> Save
          </button>
          <button type="button" className="flex items-center gap-1 hover:text-navy-600 dark:hover:text-navy-200">
            <MoreHorizontal size={13} /> More
          </button>
        </div>
      </div>
    </div>
  );
}
