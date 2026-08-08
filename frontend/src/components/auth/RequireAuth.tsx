import { ReactNode, useEffect, useState } from "react";
import Link from "next/link";
import { isAuthed } from "@/lib/auth";

/** Guards a page: once mounted on the client, if there is no OIDC session it
 *  shows a login prompt instead of the (always-unauthenticated) content.
 *  Uses a `mounted` flag so server and first client render match (no
 *  hydration mismatch). Keeps the mandated 5-tab nav intact. */
export function RequireAuth({ children }: { children: ReactNode }) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  if (!mounted) return null;

  if (!isAuthed()) {
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
