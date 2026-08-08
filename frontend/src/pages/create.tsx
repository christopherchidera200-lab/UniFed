import { useState } from "react";
import { Plus, Image as ImageIcon, Send } from "lucide-react";
import { SectionHeader, Card, IconBadge } from "@/components/ui/Card";

/** Create — compose a post / announcement to the university community. */
export default function CreatePage() {
  const [text, setText] = useState("");

  return (
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
        <div className="flex items-center justify-between mt-3">
          <button className="flex items-center gap-1.5 text-ink-muted text-sm hover:text-saffron-600 transition-colors">
            <ImageIcon size={16} /> Media
          </button>
          <button
            disabled={!text.trim()}
            className="flex items-center gap-1.5 text-sm px-4 py-1.5 rounded-md bg-navy-600
                       text-white font-medium hover:bg-navy-700 transition-colors disabled:opacity-50"
          >
            <Send size={14} /> Post
          </button>
        </div>
      </Card>
      <p className="text-ink-muted text-xs text-center">
        Posts publish to your university&apos;s federated timeline.
      </p>
    </div>
  );
}
