import { act, renderHook, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useInvestigation } from '../use-investigation';
import { ApiError } from '@/lib/api/errors';
import type { StreamHandlers } from '@/lib/api/investigation-stream';
import type { CollectorResult, Investigation } from '@/lib/api/types';

// The hook is tested against a mocked transport: we are verifying state
// transitions and cancellation semantics, not SSE parsing (covered separately).
const streamMock = vi.hoisted(() => vi.fn());
vi.mock('@/lib/api/investigation-stream', () => ({ streamInvestigation: streamMock }));

function collector(name: string, findings = 1): CollectorResult {
  return {
    collector: name,
    status: 'ok',
    duration_ms: 100,
    cached: false,
    error: null,
    findings: Array.from({ length: findings }, (_, i) => ({
      collector: name,
      title: `${name} finding ${i}`,
      severity: 'info' as const,
      data: {},
      source: 'test',
      legal_basis: 'test basis',
    })),
  };
}

function investigation(results: CollectorResult[]): Investigation {
  return {
    investigation_id: 'abc',
    target: 'example.com',
    target_type: 'domain',
    created_at: '2026-08-02T12:00:00Z',
    duration_ms: 500,
    results,
    risk: { score: 12, band: 'low', rationale: ['reason one'] },
    findings_count: results.reduce((n, r) => n + r.findings.length, 0),
  };
}

describe('useInvestigation', () => {
  beforeEach(() => streamMock.mockReset());
  afterEach(() => vi.restoreAllMocks());

  it('starts idle', () => {
    const { result } = renderHook(() => useInvestigation());
    expect(result.current.phase).toBe('idle');
    expect(result.current.results).toEqual([]);
  });

  it('enters the streaming phase immediately on start', async () => {
    streamMock.mockImplementation(() => new Promise(() => {}));
    const { result } = renderHook(() => useInvestigation());

    act(() => result.current.start('example.com', 'domain'));

    expect(result.current.phase).toBe('streaming');
    expect(result.current.target).toBe('example.com');
  });

  it('derives pending collectors from the started event', async () => {
    streamMock.mockImplementation(async (_req: unknown, handlers: StreamHandlers) => {
      handlers.onStarted?.({
        investigation_id: 'abc',
        target: 'example.com',
        target_type: 'domain',
        collectors: ['dns', 'tls', 'whois'],
      });
      await new Promise(() => {});
    });

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('example.com', 'domain'));

    // Every advertised source gets a placeholder before any result arrives.
    await waitFor(() => expect(result.current.pending).toEqual(['dns', 'tls', 'whois']));
  });

  it('moves a collector out of pending as its result arrives', async () => {
    let handlersRef: StreamHandlers = {};
    streamMock.mockImplementation(async (_req: unknown, handlers: StreamHandlers) => {
      handlersRef = handlers;
      handlers.onStarted?.({
        investigation_id: 'abc',
        target: 'example.com',
        target_type: 'domain',
        collectors: ['dns', 'tls'],
      });
      await new Promise(() => {});
    });

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('example.com', 'domain'));
    await waitFor(() => expect(result.current.pending).toHaveLength(2));

    act(() => handlersRef.onCollector?.(collector('dns')));

    // This incremental fill is the entire user-visible benefit of streaming.
    await waitFor(() => {
      expect(result.current.results.map((r) => r.collector)).toEqual(['dns']);
      expect(result.current.pending).toEqual(['tls']);
    });
  });

  it('completes with the final scored investigation', async () => {
    streamMock.mockImplementation(async (_req: unknown, handlers: StreamHandlers) => {
      handlers.onStarted?.({
        investigation_id: 'abc',
        target: 'example.com',
        target_type: 'domain',
        collectors: ['dns'],
      });
      handlers.onCollector?.(collector('dns'));
      handlers.onComplete?.(investigation([collector('dns')]));
    });

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('example.com', 'domain'));

    await waitFor(() => expect(result.current.phase).toBe('complete'));
    expect(result.current.investigation?.risk.score).toBe(12);
    expect(result.current.pending).toEqual([]);
  });

  it('surfaces an ApiError as the error phase', async () => {
    streamMock.mockRejectedValue(new ApiError('validation', 'bad target', { code: 'invalid_target' }));

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('!!', 'domain'));

    await waitFor(() => expect(result.current.phase).toBe('error'));
    expect(result.current.error?.code).toBe('invalid_target');
  });

  it('wraps a non-ApiError rejection rather than leaking it', async () => {
    streamMock.mockRejectedValue(new Error('boom'));

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('example.com', 'domain'));

    await waitFor(() => expect(result.current.phase).toBe('error'));
    expect(result.current.error).toBeInstanceOf(ApiError);
  });

  it('does not report an error when the run was cancelled deliberately', async () => {
    streamMock.mockImplementation(async (_r: unknown, _h: unknown, signal: AbortSignal) => {
      await new Promise<void>((resolve) => signal.addEventListener('abort', () => resolve()));
      throw new DOMException('Aborted', 'AbortError');
    });

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('example.com', 'domain'));
    act(() => result.current.cancel());

    // Cancelling is a user action; showing a red error box for it would be wrong.
    await waitFor(() => expect(result.current.phase).not.toBe('error'));
  });

  it('leaves the streaming phase when cancelled with no results yet', async () => {
    // Regression: abort() stops the transport but does not change phase, which
    // left the UI stuck showing a Cancel button and no way back.
    streamMock.mockImplementation(() => new Promise(() => {}));

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('example.com', 'domain'));
    expect(result.current.phase).toBe('streaming');

    act(() => result.current.cancel());

    expect(result.current.phase).toBe('idle');
  });

  it('keeps partial results when cancelled mid-run', async () => {
    let handlersRef: StreamHandlers = {};
    streamMock.mockImplementation(async (_r: unknown, handlers: StreamHandlers) => {
      handlersRef = handlers;
      handlers.onStarted?.({
        investigation_id: 'abc',
        target: 'example.com',
        target_type: 'domain',
        collectors: ['dns', 'tls'],
      });
      await new Promise(() => {});
    });

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('example.com', 'domain'));
    act(() => handlersRef.onCollector?.(collector('dns')));
    await waitFor(() => expect(result.current.results).toHaveLength(1));

    act(() => result.current.cancel());

    // Findings already retrieved are real; stopping a slow run must not discard them.
    expect(result.current.phase).toBe('complete');
    expect(result.current.results).toHaveLength(1);
  });

  it('aborts the previous run when a new one starts', async () => {
    const signals: AbortSignal[] = [];
    streamMock.mockImplementation(async (_r: unknown, _h: unknown, signal: AbortSignal) => {
      signals.push(signal);
      await new Promise(() => {});
    });

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('first.com', 'domain'));
    act(() => result.current.start('second.com', 'domain'));

    // Otherwise late results from the first target would pollute the second report.
    expect(signals[0]?.aborted).toBe(true);
    expect(signals[1]?.aborted).toBe(false);
  });

  it('ignores events from a run that was already aborted', async () => {
    let handlersRef: StreamHandlers = {};
    streamMock.mockImplementation(async (_r: unknown, handlers: StreamHandlers) => {
      handlersRef = handlers;
      await new Promise(() => {});
    });

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('example.com', 'domain'));
    act(() => result.current.cancel());
    act(() => handlersRef.onCollector?.(collector('stale')));

    expect(result.current.results).toEqual([]);
  });

  it('aborts the in-flight request on unmount', async () => {
    let captured: AbortSignal | undefined;
    streamMock.mockImplementation(async (_r: unknown, _h: unknown, signal: AbortSignal) => {
      captured = signal;
      await new Promise(() => {});
    });

    const { result, unmount } = renderHook(() => useInvestigation());
    act(() => result.current.start('example.com', 'domain'));
    unmount();

    expect(captured?.aborted).toBe(true);
  });

  it('reset returns the hook to idle', async () => {
    streamMock.mockImplementation(async (_req: unknown, handlers: StreamHandlers) => {
      handlers.onComplete?.(investigation([collector('dns')]));
    });

    const { result } = renderHook(() => useInvestigation());
    act(() => result.current.start('example.com', 'domain'));
    await waitFor(() => expect(result.current.phase).toBe('complete'));

    act(() => result.current.reset());
    expect(result.current.phase).toBe('idle');
    expect(result.current.investigation).toBeNull();
  });
});
