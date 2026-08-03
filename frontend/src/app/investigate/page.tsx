import type { Metadata } from 'next';
import { AppShell } from '@/components/layout/app-shell';
import { InvestigationWorkspace } from '@/components/investigation/investigation-workspace';

export const metadata: Metadata = {
  title: 'Investigate',
  description: 'Run a legal OSINT investigation against a domain, IP, email or username.',
};

export default function InvestigatePage() {
  return (
    <AppShell>
      <div className="space-y-6">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">Investigate</h1>
          <p className="mt-1 text-sm text-subtle">
            Query every applicable public source in parallel. Results stream in as each source
            responds.
          </p>
        </div>
        <InvestigationWorkspace />
      </div>
    </AppShell>
  );
}
