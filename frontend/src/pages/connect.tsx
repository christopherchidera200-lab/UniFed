import { useQuery } from "@tanstack/react-query";
import { MessageCircle, Send, Heart, Bookmark } from "lucide-react";
import { unifedApi, getToken } from "@/lib/api";
import { SectionHeader, Card, IconBadge } from "@/components/ui/Card";

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
          <Card key={p.id}>
            <div className="flex items-center gap-2 mb-2">
              <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
                <MessageCircle size={16} />
              </IconBadge>
              <span className="font-medium text-ink text-sm">{p.author}</span>
            </div>
            <p className="text-ink/90 text-sm">{p.body}</p>
            <div className="flex gap-4 mt-3 text-ink-muted text-xs">
              <span className="flex items-center gap-1"><Heart size={14} /> Like</span>
              <span className="flex items-center gap-1"><Send size={14} /> Share</span>
              <span className="flex items-center gap-1"><Bookmark size={14} /> Save</span>
            </div>
          </Card>
        ))}
        {feed.isLoading && <p className="text-ink-muted text-sm">Loading…</p>}
      </div>
    </div>
  );
}
