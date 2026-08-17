import { cn } from "@/lib/cn";

/**
 * Federation badge — shows a post/profile's home institution at a glance.
 * Color is the institution's crest color (tokens.color.fed). Solves the
 * Mastodon "can't tell the instance" problem: cross-campus content is
 * instantly legible.
 */
export type InstitutionSlug = "adun" | "uniabuja" | "unn" | "oau" | (string & {});

const LABELS: Record<string, string> = {
  adun: "ADUN", uniabuja: "UniAbuja", unn: "UNN", oau: "OAU"
};

export function FederationBadge({
  slug, name, className
}: { slug?: string | null; name?: string | null; className?: string }) {
  const key = (slug ?? "").toLowerCase();
  const label = LABELS[key] ?? (name ? name.slice(0, 4).toUpperCase() : "UNI");
  // Fall back to a neutral chip when the slug isn't in the known palette.
  const known = key in LABELS;
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-pill px-2 py-0.5 text-[10px] font-bold text-white",
        known ? `bg-fed-${key}` : "bg-navy-600",
        className
      )}
      title={name ?? label}
    >
      ◆ {label}
    </span>
  );
}
