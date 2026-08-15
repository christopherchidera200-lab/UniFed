import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Plus, Image as ImageIcon, Send, AlertTriangle, CheckCircle2, FileText } from "lucide-react";
import { SectionHeader, Card, IconBadge } from "@/components/ui/Card";
import { RequireAuth } from "@/components/auth/RequireAuth";
import { unifedApi, getToken, type ProfileDTO } from "@/lib/api";
import Link from "next/link";

/** Create — compose a post / announcement to the university community. */
export default function CreatePage() {
  const token = getToken();
  const [text, setText] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [posted, setPosted] = useState(false);

  const profile = useQuery<ProfileDTO>({
    queryKey: ["profile"], queryFn: () => unifedApi.profile(token), enabled: Boolean(token)
  });
  const isLecturer = profile.data?.actor_type === "staff" || profile.data?.actor_type === "admin";

  async function handlePost() {
    const body = text.trim();
    if (!body || submitting) return;
    if (!token) {
      setError("You need to be signed in to post.");
      return;
    }
    setSubmitting(true);
    setError(null);
    setPosted(false);
    try {
      await unifedApi.createPost(token, body);
      setText("");
      setPosted(true);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not publish your post.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <RequireAuth>
    <div className="space-y-6">
      <SectionHeader title="Create" eyebrow="Share with your community" />
      <Card>
        <div className="flex items-start gap-3">
          <IconBadge className="bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300">
            <Plus size={18} />
          </IconBadge>
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="What's happening at your university?"
            rows={4}
            className="flex-1 resize-none rounded-xl border border-navy-100 dark:border-navy-800
                       bg-white dark:bg-navy-950 p-3 text-sm text-ink outline-none
                       focus:border-saffron-400 focus:ring-2 focus:ring-saffron-200 dark:focus:ring-saffron-500/30"
          />
        </div>
        {error && (
          <p className="flex items-center gap-2 mt-3 text-sm text-amber-700 dark:text-amber-300">
            <AlertTriangle size={16} /> {error}
          </p>
        )}
        {posted && (
          <p className="flex items-center gap-2 mt-3 text-sm text-emerald-600 dark:text-emerald-400">
            <CheckCircle2 size={16} /> Posted to your community.
          </p>
        )}
        <div className="flex items-center justify-between mt-3">
          <button className="flex items-center gap-1.5 text-ink-muted text-sm hover:text-saffron-600 transition-colors">
            <ImageIcon size={16} /> Media
          </button>
          <button
            onClick={handlePost}
            disabled={!text.trim() || submitting}
            className="flex items-center gap-1.5 text-sm px-4 py-1.5 rounded-md bg-navy-600
                       text-white font-medium hover:bg-navy-700 transition-colors disabled:opacity-50"
          >
            <Send size={14} /> {submitting ? "Posting…" : "Post"}
          </button>
        </div>
      </Card>
      <p className="text-ink-muted text-xs text-center">
        Posts publish to your university&apos;s federated timeline.
      </p>

      {isLecturer && (
        <Link href="/assignments" className="card card-hover flex items-center gap-3 p-4">
          <IconBadge className="bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300">
            <FileText size={18} />
          </IconBadge>
          <div>
            <div className="font-medium text-ink">Manage Assignments</div>
            <div className="text-ink-subtle text-xs">Create and grade coursework for your courses</div>
          </div>
        </Link>
      )}
    </div>
    </RequireAuth>
  );
}
