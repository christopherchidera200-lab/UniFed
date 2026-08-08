import { ReactNode } from "react";
import Link from "next/link";
import { isAuthed } from "@/lib/auth";

/** Guards a page: if there is no OIDC session, show a login prompt instead of
 *  the (always-unauthenticated) content. Keeps the mandated 5-tab nav intact. */
export function RequireAuth({ children }: { children: ReactNode }) {
  if (typeof window !== "undefined" && !isAuthed()) {
    return (
      <section className="space-y-4 py-8 text-center">
        <h1 className="font-display text-xl font-bold">Sign in to continue</h1>
        <p className="text-ink-muted text-sm">
          This section needs your UniFed credentials.
        </p>
        <Link
          href="/login"
          className="inline-block mt-2 px-4 py-2 rounded-md bg-navy-600 text-white
                     font-medium hover:bg-navy-700 transition-colors"
        >
          Go to login
        </Link>
      </section>
    );
  }
  return <>{children}</>;
}
