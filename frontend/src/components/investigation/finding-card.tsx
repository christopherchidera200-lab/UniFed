'use client';

import { useState } from 'react';
import { ChevronRight, Scale } from 'lucide-react';
import { Badge, severityTone } from '@/components/ui/badge';
import { cn } from '@/lib/utils/cn';
import type { Finding } from '@/lib/api/types';

/**
 * One finding, collapsed by default.
 *
 * UX rationale: an investigation can produce dozens of findings, most of them
 * informational. Showing every payload expanded turns the report into a wall of
 * JSON. The title plus severity is enough to triage; detail is one click away.
 *
 * The legal basis is shown on expand rather than hidden in a tooltip — it is the
 * product's core claim, and an analyst compiling a report needs to cite it.
 */
export function FindingCard({ finding }: { finding: Finding }) {
  const [expanded, setExpanded] = useState(false);
  const hasData = Object.keys(finding.data).length > 0;

  return (
    <div className="border-b border-border last:border-b-0">
      <button
        type="button"
        onClick={() => setExpanded((value) => !value)}
        aria-expanded={expanded}
        className={cn(
          'flex w-full items-start gap-3 px-4 py-3 text-left transition-colors',
          'hover:bg-muted focus-visible:bg-muted',
        )}
      >
        <ChevronRight
          aria-hidden="true"
          className={cn(
            'mt-0.5 h-3.5 w-3.5 shrink-0 text-subtle transition-transform duration-200',
            expanded && 'rotate-90',
          )}
        />
        <span className="min-w-0 flex-1">
          <span className="block text-sm text-foreground">{finding.title}</span>
          <span className="mt-0.5 block truncate text-xs text-subtle">{finding.source}</span>
        </span>
        <Badge tone={severityTone(finding.severity)}>{finding.severity}</Badge>
      </button>

      {expanded && (
        <div className="animate-slide-up space-y-3 bg-elevated px-4 pb-4 pl-10 pt-1">
          {hasData && (
            <pre className="overflow-x-auto rounded border border-border bg-canvas p-3 font-mono text-xs leading-relaxed text-foreground">
              {JSON.stringify(finding.data, null, 2)}
            </pre>
          )}
          <p className="flex items-start gap-2 text-xs leading-relaxed text-subtle">
            <Scale className="mt-0.5 h-3 w-3 shrink-0" aria-hidden="true" />
            <span>
              <span className="font-medium text-foreground">Legal basis: </span>
              {finding.legal_basis}
            </span>
          </p>
        </div>
      )}
    </div>
  );
}
