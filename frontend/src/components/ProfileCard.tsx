import { User } from "lucide-react";
import { cn } from "@/lib/cn";
import { FederationBadge } from "./FederationBadge";
import { RoleBadge } from "./RoleBadge";
import type { ProfileDTO } from "@/lib/api";

/**
 * Profile card — MUST bind to the authenticated session, never hardcoded.
 * Contract (verified live in pages/profile.tsx):
 *   useQuery(['profile']) -> unifedApi.profile(token) returns ProfileDTO
 *   { display_name, email, actor_type, bio, skills[], university{name,short_name,slug} }
 * Avatar initials are derived from display_name. No placeholder data.
 */
export function ProfileCard({
  profile, className
}: { profile: ProfileDTO; className?: string }) {
  const name = profile.display_name || "UniFed User";
  const initials = name.split(/\s+/).map((p) => p[0]).slice(0, 2).join("").toUpperCase();
  return (
    <div className={cn(
      "flex items-center gap-4 rounded-md border border-navy-100 dark:border-navy-800 bg-white dark:bg-navy-900 p-4",
      className
    )}>
      <span className="grid h-14 w-14 shrink-0 place-items-center rounded-2xl bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300">
        {initials || <User size={26} />}
      </span>
      <div className="min-w-0">
        <div className="flex items-center gap-1.5">
          <span className="truncate font-display font-bold text-lg text-ink dark:text-navy-50">{name}</span>
          {profile.actor_type ? <RoleBadge role={profile.actor_type} /> : null}
        </div>
        <div className="truncate text-sm text-ink-muted">{profile.email}</div>
        <div className="mt-0.5 flex items-center gap-1.5">
          {profile.university ? (
            <span className="text-xs text-ink-subtle">
              {profile.university.name}
              {profile.university.short_name ? ` · ${profile.university.short_name}` : ""}
            </span>
          ) : null}
          {profile.university?.slug ? (
            <FederationBadge slug={profile.university.slug} name={profile.university.name} />
          ) : null}
        </div>
      </div>
    </div>
  );
}
