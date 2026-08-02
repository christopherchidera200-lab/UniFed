import { ShieldCheck, Radar, ScrollText } from 'lucide-react';
import { ThemeToggle } from '@/components/theme/theme-toggle';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';

/**
 * Landing surface.
 *
 * Phase 0 scope: this page exists to prove the design system, theming and
 * accessibility scaffolding render correctly end to end. The investigation
 * workspace replaces it in Phase 2.
 */
export default function HomePage() {
  return (
    <div className="flex min-h-dvh flex-col">
      <header className="sticky top-0 z-40 border-b border-border bg-canvas/80 backdrop-blur">
        <div className="mx-auto flex h-14 w-full max-w-5xl items-center justify-between px-4 sm:px-6">
          <div className="flex items-center gap-2">
            <span
              aria-hidden="true"
              className="flex h-6 w-6 items-center justify-center rounded bg-accent text-accent-foreground"
            >
              <Radar className="h-3.5 w-3.5" />
            </span>
            <span className="text-sm font-semibold tracking-tight">CloudIntel</span>
            <Badge tone="neutral">Phase 0</Badge>
          </div>
          <ThemeToggle />
        </div>
      </header>

      <main id="main" className="mx-auto w-full max-w-5xl flex-1 px-4 py-16 sm:px-6">
        <div className="max-w-2xl animate-slide-up">
          <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">
            Legal OSINT, aggregated.
          </h1>
          <p className="mt-4 text-sm leading-relaxed text-subtle sm:text-base">
            CloudIntel unifies public intelligence on domains, IP addresses, emails and usernames
            into a single reviewable investigation — with the legal basis recorded alongside every
            finding.
          </p>
        </div>

        <div className="mt-12 grid gap-4 sm:grid-cols-3">
          <Feature
            icon={<ShieldCheck className="h-4 w-4" aria-hidden="true" />}
            title="Lawful by construction"
            body="Every collector declares its legal basis as a required field. Sources that cannot justify themselves cannot ship."
          />
          <Feature
            icon={<Radar className="h-4 w-4" aria-hidden="true" />}
            title="Concurrent collection"
            body="Collectors fan out in parallel behind isolation boundaries, so one slow source never stalls an investigation."
          />
          <Feature
            icon={<ScrollText className="h-4 w-4" aria-hidden="true" />}
            title="Explainable scoring"
            body="Risk scores are rule-based and carry a rationale for every point, so an analyst can defend the number."
          />
        </div>
      </main>

      <footer className="border-t border-border">
        <div className="mx-auto w-full max-w-5xl px-4 py-6 text-xs text-subtle sm:px-6">
          Public sources and authorized APIs only. See{' '}
          <code className="font-mono text-[0.7rem]">docs/LEGAL_AND_ETHICS.md</code>.
        </div>
      </footer>
    </div>
  );
}

function Feature({ icon, title, body }: { icon: React.ReactNode; title: string; body: string }) {
  return (
    <Card className="transition-shadow duration-200 hover:shadow-md">
      <CardContent className="space-y-2">
        <span className="flex h-8 w-8 items-center justify-center rounded bg-accent-subtle text-accent">
          {icon}
        </span>
        <h2 className="text-sm font-medium">{title}</h2>
        <p className="text-xs leading-relaxed text-subtle">{body}</p>
      </CardContent>
    </Card>
  );
}
