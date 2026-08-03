'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { ApiError } from '@/lib/api/errors';
import { streamInvestigation, type InvestigationStarted } from '@/lib/api/investigation-stream';
import type { CollectorResult, Investigation, TargetType } from '@/lib/api/types';

/**
 * Lifecycle of an investigation from the UI's point of view.
 *
 * `streaming` is distinct from `idle` and `complete` because the UI renders three
 * genuinely different things: an empty prompt, a partially-filled grid with
 * pending placeholders, and a final scored report.
 */
export type InvestigationPhase = 'idle' | 'streaming' | 'complete' | 'error';

export interface InvestigationState {
  phase: InvestigationPhase;
  /** Target being investigated, echoed back from the server (normalised). */
  target: string | null;
  /** Collector names the run will attempt. Drives pending placeholders. */
  expected: string[];
  /** Results received so far, in completion order (fastest first). */
  results: CollectorResult[];
  /** Populated only once the `complete` event lands. */
  investigation: Investigation | null;
  error: ApiError | null;
}

const INITIAL: InvestigationState = {
  phase: 'idle',
  target: null,
  expected: [],
  results: [],
  investigation: null,
  error: null,
};

export interface UseInvestigationResult extends InvestigationState {
  /** Collector names still pending, derived from `expected` minus received. */
  pending: string[];
  start: (target: string, targetType: TargetType) => void;
  cancel: () => void;
  reset: () => void;
}

/**
 * Owns the state of a single streaming investigation.
 *
 * Guarantees:
 *   - Starting a new run aborts the previous one, so results cannot interleave.
 *   - Unmounting aborts the in-flight request rather than leaking it.
 *   - A deliberate abort never surfaces as an error to the user.
 */
export function useInvestigation(): UseInvestigationResult {
  const [state, setState] = useState<InvestigationState>(INITIAL);
  const controllerRef = useRef<AbortController | null>(null);
  // Guards against a late event from an aborted run writing to state after the
  // component has gone away.
  const mountedRef = useRef(true);

  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
      controllerRef.current?.abort();
    };
  }, []);

  const cancel = useCallback(() => {
    controllerRef.current?.abort();
    controllerRef.current = null;
    // Abort only stops the transport; the phase must be returned to a usable
    // state explicitly or the UI stays stuck showing "Cancel" forever.
    // Partial results already received are deliberately kept — they are real
    // findings, and discarding them would punish the user for stopping a slow run.
    setState((previous) =>
      previous.phase === 'streaming'
        ? { ...previous, phase: previous.results.length > 0 ? 'complete' : 'idle' }
        : previous,
    );
  }, []);

  const reset = useCallback(() => {
    cancel();
    setState(INITIAL);
  }, [cancel]);

  const start = useCallback(
    (target: string, targetType: TargetType) => {
      // Abort any run already in flight before starting another.
      controllerRef.current?.abort();
      const controller = new AbortController();
      controllerRef.current = controller;

      setState({ ...INITIAL, phase: 'streaming', target });

      void streamInvestigation(
        { target, target_type: targetType },
        {
          onStarted: (payload: InvestigationStarted) => {
            if (!mountedRef.current || controller.signal.aborted) return;
            setState((previous) => ({
              ...previous,
              target: payload.target,
              expected: payload.collectors,
            }));
          },
          onCollector: (result: CollectorResult) => {
            if (!mountedRef.current || controller.signal.aborted) return;
            setState((previous) => ({
              ...previous,
              results: [...previous.results, result],
            }));
          },
          onComplete: (investigation: Investigation) => {
            if (!mountedRef.current || controller.signal.aborted) return;
            setState((previous) => ({
              ...previous,
              phase: 'complete',
              investigation,
              // Trust the server's final, sorted result set over our arrival-ordered one.
              results: investigation.results,
            }));
          },
        },
        controller.signal,
      ).catch((cause: unknown) => {
        // A cancelled run is a user action, not a failure to report.
        if (controller.signal.aborted) return;
        if (!mountedRef.current) return;

        setState((previous) => ({
          ...previous,
          phase: 'error',
          error:
            cause instanceof ApiError
              ? cause
              : new ApiError('unknown', 'The investigation failed', { cause }),
        }));
      });
    },
    [],
  );

  const received = new Set(state.results.map((result) => result.collector));
  const pending = state.expected.filter((name) => !received.has(name));

  return { ...state, pending, start, cancel, reset };
}
