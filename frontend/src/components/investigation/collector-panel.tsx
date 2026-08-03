import { AlertTriangle, Check, CircleSlash, Clock, Loader2 } from 'lucide-react';
import { Badge, statusTone } from '@/components/ui/badge';
import { FindingCard } from './finding-card';
import { formatDuration, pluralize } from '@/lib/utils/format';
import { cn } from '@/lib/utils/cn';
import type { CollectorResult, CollectorStatus } from '@/lib/api/types';

const STATUS_ICON: Record<CollectorStatus, typeof Check> = {
  ok: Check,
  empty: CircleSlash,
  timeout: Clock,
  error: AlertTriangle,
  skipped: CircleSlash,
};

/** Copy shown when a collector returns no findings. Never a bare "No data". */
const STATUS_MESSAGE: Record<CollectorStatus, string> = {
  ok: '',
  empty: 'This source had no records for the target. That is a normal result, not a failure.',
  timeout: 'The source did not respond in time. Other sources were unaffected.',
  error: 'The source could not be reached. Other sources were unaffected.',
  skipped: 'This source does not apply to this target type.',
};

export interface CollectorPanelProps {
  result: CollectorResult;
}

/** One collector's contribution to the investigation. */
export function CollectorPanel({ result }: CollectorPanelProps) {
  const Icon = STATUS_ICON[result.status];
  const message = STATUS_MESSAGE[result.status];

  return (
    <section
      className="animate-slide-up overflow-hidden rounded-lg border border-border bg-surface shadow-xs"
      aria-labelledby={`collector-${result.collector}`}
    >
      <header className="flex items-center justify-between gap-3 border-b border-border px-4 py-3">
        <div className="flex min-w-0 items-center gap-2">
          <Icon
            aria-hidden="true"
            className={cn(
              'h-3.5 w-3.5 shrink-0',
              result.status === 'ok' && 'text-success',
              result.status === 'error' && 'text-severity-high',
              result.status === 'timeout' && 'text-severity-medium',
              (result.status === 'empty' || result.status === 'skipped') && 'text-subtle',
            )}
          />
          <h3
            id={`collector-${result.collector}`}
            className="truncate text-sm font-medium capitalize"
          >
            {result.collector}
          </h3>
          {result.cached && <Badge tone="neutral">cached</Badge>}
        </div>

        <div className="flex shrink-0 items-center gap-2">
          <span className="text-xs tabular-nums text-subtle">
            {formatDuration(result.duration_ms)}
          </span>
          <Badge tone={statusTone(result.status)}>{result.status}</Badge>
        </div>
      </header>

      {result.findings.length > 0 ? (
        <>
          <p className="sr-only">{pluralize(result.findings.length, 'finding')}</p>
          <div>
            {result.findings.map((finding, index) => (
              <FindingCard key={`${finding.collector}-${index}`} finding={finding} />
            ))}
          </div>
        </>
      ) : (
        <p className="px-4 py-4 text-xs leading-relaxed text-subtle">
          {message || 'No findings returned.'}
          {result.error && (
            <span className="mt-1 block font-mono text-2xs text-subtle">{result.error}</span>
          )}
        </p>
      )}
    </section>
  );
}

/** Placeholder for a collector that has not reported yet. */
export function CollectorPending({ name }: { name: string }) {
  return (
    <section
      className="overflow-hidden rounded-lg border border-border bg-surface shadow-xs"
      aria-label={`${name} — in progress`}
    >
      <header className="flex items-center justify-between gap-3 border-b border-border px-4 py-3">
        <div className="flex items-center gap-2">
          <Loader2 className="h-3.5 w-3.5 animate-spin text-subtle" aria-hidden="true" />
          <h3 className="text-sm font-medium capitalize text-subtle">{name}</h3>
        </div>
        <Badge tone="neutral">running</Badge>
      </header>
      <div className="space-y-2 px-4 py-4">
        <div className="h-3 w-3/4 animate-pulse rounded bg-muted" />
        <div className="h-3 w-1/2 animate-pulse rounded bg-muted" />
      </div>
    </section>
  );
}
