import { AlertTriangle } from "lucide-react";
import { useSession } from "@/lib/session";

/**
 * Non-intrusive session-status affordance. Shows only when the access token is
 * within the warning window, so users can refresh before a silent logout.
 * Stops short of the full backend fix — which is refreshSession() in auth.ts.
 */
export function SessionToast() {
  const { warning, staySignedIn } = useSession();
  if (!warning) return null;
  return (
    <div
      role="status"
      className="fixed inset-x-3 bottom-[72px] z-50 flex items-center gap-2.5 rounded-xl border border-navy-200 dark:border-navy-700 bg-navy-50 dark:bg-navy-800 px-3.5 py-2.5 text-sm text-ink dark:text-navy-50 shadow-lift"
    >
      <AlertTriangle size={16} className="text-saffron-500 shrink-0" />
      <span className="flex-1">Session expiring soon — tap to stay signed in.</span>
      <button
        type="button"
        onClick={() => staySignedIn()}
        className="rounded-lg bg-saffron-500 px-3 py-1 font-semibold text-[#1a1003]"
      >
        Stay
      </button>
    </div>
  );
}
