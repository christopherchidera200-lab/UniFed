import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { streamInvestigation } from '../investigation-stream';
import { ApiError } from '../errors';
import type { CollectorResult, Investigation } from '../types';

const ORIGINAL_FETCH = globalThis.fetch;

function sseResponse(frames: string[], status = 200): Response {
  const encoder = new TextEncoder();
  const body = new ReadableStream<Uint8Array>({
    start(controller) {
      for (const frame of frames) controller.enqueue(encoder.encode(frame));
      controller.close();
    },
  });
  return new Response(body, { status, headers: { 'Content-Type': 'text/event-stream' } });
}

const STARTED = 'event: started\ndata: {"investigation_id":"abc","target":"example.com","target_type":"domain","collectors":["dns","tls"]}\n\n';
const COLLECTOR = 'event: collector\ndata: {"collector":"dns","status":"ok","duration_ms":120,"findings":[],"error":null,"cached":false}\n\n';
const COMPLETE = 'event: complete\ndata: {"investigation_id":"abc","target":"example.com","target_type":"domain","created_at":"2026-08-02T12:00:00Z","duration_ms":300,"results":[],"risk":{"score":5,"band":"low","rationale":[]},"findings_count":0}\n\n';

describe('streamInvestigation', () => {
  beforeEach(() => vi.stubEnv('NEXT_PUBLIC_API_BASE_URL', 'http://api.test'));
  afterEach(() => {
    globalThis.fetch = ORIGINAL_FETCH;
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
  });

  it('invokes handlers in event order', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue(sseResponse([STARTED, COLLECTOR, COMPLETE]));
    const calls: string[] = [];

    await streamInvestigation(
      { target: 'example.com', target_type: 'domain' },
      {
        onStarted: () => calls.push('started'),
        onCollector: () => calls.push('collector'),
        onComplete: () => calls.push('complete'),
      },
    );

    expect(calls).toEqual(['started', 'collector', 'complete']);
  });

  it('passes the advertised collector list to onStarted', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue(sseResponse([STARTED]));
    const onStarted = vi.fn();

    await streamInvestigation({ target: 'example.com', target_type: 'domain' }, { onStarted });

    expect(onStarted).toHaveBeenCalledWith(
      expect.objectContaining({ collectors: ['dns', 'tls'], target: 'example.com' }),
    );
  });

  it('decodes collector results with their typed status', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue(sseResponse([STARTED, COLLECTOR]));
    const received: CollectorResult[] = [];

    await streamInvestigation(
      { target: 'example.com', target_type: 'domain' },
      { onCollector: (result) => received.push(result) },
    );

    expect(received[0]?.collector).toBe('dns');
    expect(received[0]?.status).toBe('ok');
  });

  it('decodes the final scored investigation', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue(sseResponse([STARTED, COMPLETE]));
    let final: Investigation | null = null;

    await streamInvestigation(
      { target: 'example.com', target_type: 'domain' },
      { onComplete: (investigation) => (final = investigation) },
    );

    expect(final!.risk.score).toBe(5);
    expect(final!.risk.band).toBe('low');
  });

  it('POSTs to the stream endpoint requesting an event stream', async () => {
    const fetchMock = vi.fn().mockResolvedValue(sseResponse([STARTED]));
    globalThis.fetch = fetchMock;

    await streamInvestigation({ target: 'example.com', target_type: 'domain' }, {});

    expect(fetchMock.mock.calls[0]?.[0]).toBe('http://api.test/investigations/stream');
    const init = fetchMock.mock.calls[0]?.[1] as RequestInit;
    expect(init.method).toBe('POST');
    expect((init.headers as Record<string, string>).Accept).toBe('text/event-stream');
  });

  it('raises a validation ApiError when the target is rejected before the stream opens', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ error: 'invalid_target', message: 'bad domain' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      }),
    );

    const error = (await streamInvestigation(
      { target: '!!', target_type: 'domain' },
      {},
    ).catch((e: unknown) => e)) as ApiError;

    expect(error).toBeInstanceOf(ApiError);
    expect(error.kind).toBe('validation');
    expect(error.code).toBe('invalid_target');
  });

  it('raises when an in-band error event arrives mid-stream', async () => {
    const errorFrame = 'event: error\ndata: {"error":"internal_error","message":"boom"}\n\n';
    globalThis.fetch = vi.fn().mockResolvedValue(sseResponse([STARTED, errorFrame]));

    const error = (await streamInvestigation(
      { target: 'example.com', target_type: 'domain' },
      {},
    ).catch((e: unknown) => e)) as ApiError;

    expect(error.kind).toBe('server');
    expect(error.code).toBe('internal_error');
  });

  it('classifies a transport failure as a network error', async () => {
    globalThis.fetch = vi.fn().mockRejectedValue(new TypeError('Failed to fetch'));

    const error = (await streamInvestigation(
      { target: 'example.com', target_type: 'domain' },
      {},
    ).catch((e: unknown) => e)) as ApiError;

    expect(error.kind).toBe('network');
  });

  it('ignores unknown event types so the backend can add events safely', async () => {
    const future = 'event: telemetry\ndata: {"x":1}\n\n';
    globalThis.fetch = vi.fn().mockResolvedValue(sseResponse([STARTED, future, COMPLETE]));
    const onComplete = vi.fn();

    await streamInvestigation({ target: 'example.com', target_type: 'domain' }, { onComplete });

    expect(onComplete).toHaveBeenCalledOnce();
  });

  it('survives a malformed frame without aborting the stream', async () => {
    const broken = 'event: collector\ndata: {not json\n\n';
    globalThis.fetch = vi.fn().mockResolvedValue(sseResponse([STARTED, broken, COMPLETE]));
    const onComplete = vi.fn();
    const onCollector = vi.fn();

    await streamInvestigation(
      { target: 'example.com', target_type: 'domain' },
      { onCollector, onComplete },
    );

    expect(onCollector).not.toHaveBeenCalled();
    expect(onComplete).toHaveBeenCalledOnce();
  });
});
