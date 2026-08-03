import type { ReactNode } from 'react';
import Link from 'next/link';
import { Radar } from 'lucide-react';
import { ThemeToggle } from '@/components/theme/theme-toggle';

/**
 * Application chrome shared by every authenticated surface.
 *
 * Kept deliberately thin — a sticky header and a centred content column. A
 * persistent sidebar is not justified at four routes; it would consume horizontal
 * space that the findings grid uses better.
 */
export function AppShell({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-dvh flex-col">
      <header className="sticky top-0 z-40 border-b border-border bg-canvas/80 backdrop-blur">
        <div className="mx-auto flex h-14 w-full max-w-6xl items-center justify-between px-4 sm:px-6">
          <Link
            href="/"
            className="flex items-center gap-2 rounded transition-opacity hover:opacity-80"
          >
            <span
              aria-hidden="true"
              className="flex h-6 w-6 items-center justify-center rounded bg-accent text-accent-foreground"
            >
              <Radar className="h-3.5 w-3.5" />
            </span>
            <span className="text-sm font-semibold tracking-tight">CloudIntel</span>
          </Link>

          <nav aria-label="Main" className="flex items-center gap-1">
            <Link
              href="/investigate"
              className="rounded px-3 py-1.5 text-xs font-medium text-subtle transition-colors hover:bg-muted hover:text-foreground"
            >
              Investigate
            </Link>
            <ThemeToggle />
          </nav>
        </div>
      </header>

      <main id="main" className="mx-auto w-full max-w-6xl flex-1 px-4 py-8 sm:px-6">
        {children}
      </main>

      <footer className="border-t border-border">
        <div className="mx-auto w-full max-w-6xl px-4 py-6 text-xs text-subtle sm:px-6">
          Public sources and authorized APIs only. Every finding records its legal basis.
        </div>
      </footer>
    </div>
  );
}
