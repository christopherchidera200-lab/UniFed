'use client';

import { AlertCircle, Radar, ShieldCheck } from 'lucide-react';
import { useInvestigation } from '@/hooks/use-investigation';
import { TargetInput } from './target-input';
import { CollectorPanel, CollectorPending } from './collector-panel';
import { RiskGauge } from './risk-gauge';
import { Button } from '@/components/ui/button';
import { EmptyState } from '@/components/ui/empty-state';
import { formatDuration, pluralize } from '@/lib/utils/format';
import type { TargetType } from '@/lib/api/types';

/**
 * The investigation workspace: submit a target, watch sources resolve, read the report.
 *
 * Streaming is the defining interaction. Results appear the moment each collector
 * settles rather than after the slowest one finishes — measured on github.com, the
 * first real finding lands in ~2.9s instead of ~15s. Pending sources keep a
 * placeholder card so the layout never jumps as results fill in.
 */
export function InvestigationWorkspace() {
  const { phase, target, results, pending, investigation, error, start, cancel, reset } =
    useInvestigation();

  const streaming = phase === 'streaming';
  const findingsSoFar = results.reduce((total, result) => total + result.findings.length, 0);

  function handleSubmit(value: string, targetType: TargetType) {
    start(value, targetType);
  }

  return (
    <div className="space-y-6">
      <TargetInput onSubmit={handleSubmit} onCancel={cancel} busy={streaming} />

      {/*
        Live region: screen readers are told when the run starts and finishes.
        Polite, so it never interrupts what the user is currently reading.
      */}
      <p aria-live="polite" className="sr-only">
        {streaming && `Investigating ${target}. ${results.length} of ${results.length + pending.length} sources reported.`}
        {phase === 'complete' && investigation &&
          `Investigation of ${investigation.target} complete. Risk score ${investigation.risk.score} out of 100, ${investigation.risk.band}. ${pluralize(investigation.findings_count, 'finding')}.`}
        {phase === 'error' && error && `Investigation failed. ${error.userMessage}`}
      </p>

      {phase === 'idle' && (
        <EmptyState
          icon={<Radar className="h-4 w-4" aria-hidden="true" />}
          title="No investigation running"
          description="Enter a domain, IP address, email or username above. CloudIntel queries every applicable public source in parallel and streams results as they arrive."
        />
      )}

      {phase === 'error' && error && (
        <div
          role="alert"
          className="flex items-start gap-3 rounded-lg border border-severity-high/30 bg-severity-high/5 px-4 py-3"
        >
          <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-severity-high" aria-hidden="true" />
          <div className="min-w-0 flex-1">
            <p className="text-sm font-medium text-foreground">Investigation failed</p>
            <p className="mt-0.5 text-xs leading-relaxed text-subtle">{error.userMessage}</p>
          </div>
          <Button variant="secondary" size="sm" onClick={reset}>
            Dismiss
          </Button>
        </div>
      )}

      {(streaming || phase === 'complete') && (
        <>
          <header className="flex flex-wrap items-center justify-between gap-4 rounded-lg border border-border bg-surface px-5 py-4 shadow-xs">
            <div className="min-w-0">
              <p className="text-xs uppercase tracking-wide text-subtle">Target</p>
              <p className="truncate font-mono text-sm font-medium">{target}</p>
              <p className="mt-1 text-xs text-subtle">
                {streaming
                  ? `${results.length} of ${results.length + pending.length} sources reported · ${pluralize(findingsSoFar, 'finding')} so far`
                  : investigation &&
                    `${pluralize(investigation.findings_count, 'finding')} from ${pluralize(investigation.results.length, 'source')} · ${formatDuration(investigation.duration_ms)}`}
              </p>
            </div>

            {investigation ? (
              <RiskGauge score={investigation.risk.score} band={investigation.risk.band} />
            ) : (
              <p className="text-xs text-subtle">Scoring once all sources report…</p>
            )}
          </header>

          {investigation && investigation.risk.rationale.length > 0 && (
            <section
              aria-labelledby="rationale-heading"
              className="rounded-lg border border-border bg-surface px-5 py-4 shadow-xs"
            >
              <h2 id="rationale-heading" className="flex items-center gap-2 text-sm font-semibold">
                <ShieldCheck className="h-3.5 w-3.5 text-subtle" aria-hidden="true" />
                Why this score
              </h2>
              {/*
                Every point of the score carries a reason. An analyst has to be able
                to defend the number in a report, so the rationale is first-class UI,
                not a debug detail.
              */}
              <ul className="mt-3 space-y-1.5">
                {investigation.risk.rationale.map((reason, index) => (
                  <li key={index} className="flex gap-2 text-xs leading-relaxed text-subtle">
                    <span aria-hidden="true" className="text-border-strong">
                      —
                    </span>
                    <span>{reason}</span>
                  </li>
                ))}
              </ul>
            </section>
          )}

          <div className="grid gap-4 lg:grid-cols-2">
            {results.map((result) => (
              <CollectorPanel key={result.collector} result={result} />
            ))}
            {pending.map((name) => (
              <CollectorPending key={name} name={name} />
            ))}
          </div>
        </>
      )}
    </div>
  );
}
