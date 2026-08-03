import Link from 'next/link';
import { ArrowRight, Radar, ScrollText, ShieldCheck } from 'lucide-react';
import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent } from '@/components/ui/card';

export default function HomePage() {
  return (
    <AppShell>
      <div className="max-w-2xl animate-slide-up py-8">
        <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">
          Legal OSINT, aggregated.
        </h1>
        <p className="mt-4 text-sm leading-relaxed text-subtle sm:text-base">
          CloudIntel unifies public intelligence on domains, IP addresses, emails and usernames
          into a single reviewable investigation — with the legal basis recorded alongside every
          finding.
        </p>
        <Link
          href="/investigate"
          className="mt-6 inline-flex h-11 items-center gap-2 rounded-lg bg-accent px-5 text-sm font-medium text-accent-foreground shadow-xs transition-[filter] hover:brightness-110"
        >
          Start an investigation
          <ArrowRight className="h-4 w-4" aria-hidden="true" />
        </Link>
      </div>

      <div className="mt-8 grid gap-4 sm:grid-cols-3">
        <Feature
          icon={<ShieldCheck className="h-4 w-4" aria-hidden="true" />}
          title="Lawful by construction"
          body="Every collector declares its legal basis as a required field. Sources that cannot justify themselves cannot ship."
        />
        <Feature
          icon={<Radar className="h-4 w-4" aria-hidden="true" />}
          title="Streaming collection"
          body="Sources are queried in parallel and stream back as they resolve, so one slow source never holds up the rest."
        />
        <Feature
          icon={<ScrollText className="h-4 w-4" aria-hidden="true" />}
          title="Explainable scoring"
          body="Risk scores are rule-based and carry a rationale for every point, so an analyst can defend the number."
        />
      </div>
    </AppShell>
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
