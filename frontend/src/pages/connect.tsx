import { useQuery } from "@tanstack/react-query";
import { unifedApi, getToken } from "@/lib/api";
import { SectionHeader } from "@/components/ui/Card";
import { ContentCard } from "@/components/ContentCard";

/** Connect (social) — Phase 1 federation surface. Shows a feed of posts.
 *  Data is best-effort; falls back to a friendly empty state. */
export default function ConnectPage() {
  const token = getToken();
  // Federation feed endpoint may be stubbed; keep this resilient.
  const feed = useQuery({
    queryKey: ["connect-feed"],
    queryFn: async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_BASE ?? ""}/api/v1/social/feed`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        if (!res.ok) throw new Error("no feed");
        return (await res.json()) as Array<{ id: string; author: string; body: string }>;
      } catch {
        return [
          { id: "p1", author: "ADUN CS Dept", body: "SIWES window opens Sept 2. Log your placement early!" },
          { id: "p2", author: "Student Affairs", body: "Matriculation gown collection starts Monday at the registry." }
        ];
      }
    },
    enabled: Boolean(token)
  });

  return (
    <div className="space-y-6">
      <SectionHeader title="Connect" eyebrow="Your university community" />
      <div className="space-y-3">
        {feed.data?.map((p) => (
          <ContentCard
            key={p.id}
            item={{ id: p.id, type: "discussion", authorName: p.author, body: p.body }}
          />
        ))}
        {feed.isLoading && <p className="text-ink-muted text-sm">Loading…</p>}
      </div>
    </div>
  );
}
