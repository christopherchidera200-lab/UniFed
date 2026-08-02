import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { api } from '../client';
import { ApiError } from '../errors';

const ORIGINAL_FETCH = globalThis.fetch;

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

describe('api client', () => {
  beforeEach(() => {
    vi.stubEnv('NEXT_PUBLIC_API_BASE_URL', 'http://api.test');
  });

  afterEach(() => {
    globalThis.fetch = ORIGINAL_FETCH;
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
  });

  it('returns the parsed body on success', async () => {
    const payload = { status: 'ok', environment: 'test', version: '0.1.0', collectors: ['dns'] };
    globalThis.fetch = vi.fn().mockResolvedValue(jsonResponse(payload));

    await expect(api.health()).resolves.toEqual(payload);
  });

  it('strips trailing slashes from the base URL so paths never double up', async () => {
    vi.stubEnv('NEXT_PUBLIC_API_BASE_URL', 'http://api.test///');
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse([]));
    globalThis.fetch = fetchMock;

    await api.collectors();

    expect(fetchMock.mock.calls[0]?.[0]).toBe('http://api.test/collectors');
  });

  it('URL-encodes path parameters to prevent path traversal', async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse({}));
    globalThis.fetch = fetchMock;

    await api.getInvestigation('../../admin');

    expect(fetchMock.mock.calls[0]?.[0]).toBe('http://api.test/investigations/..%2F..%2Fadmin');
  });

  it('sends a JSON body and content-type on POST', async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse({}));
    globalThis.fetch = fetchMock;

    await api.createInvestigation({ target: 'example.com', target_type: 'domain' });

    const init = fetchMock.mock.calls[0]?.[1] as RequestInit;
    expect(init.method).toBe('POST');
    expect(init.body).toBe(JSON.stringify({ target: 'example.com', target_type: 'domain' }));
    expect((init.headers as Record<string, string>)['Content-Type']).toBe('application/json');
  });

  it('maps a 400 envelope onto a validation ApiError carrying the backend message', async () => {
    globalThis.fetch = vi
      .fn()
      .mockResolvedValue(
        jsonResponse({ error: 'invalid_target', message: "'!!' is not a valid domain name" }, 400),
      );

    const error = await api.health().catch((e: unknown) => e);

    expect(error).toBeInstanceOf(ApiError);
    expect((error as ApiError).kind).toBe('validation');
    expect((error as ApiError).code).toBe('invalid_target');
    expect((error as ApiError).message).toContain('not a valid domain name');
  });

  it('maps a 403 onto a forbidden ApiError', async () => {
    globalThis.fetch = vi
      .fn()
      .mockResolvedValue(jsonResponse({ error: 'forbidden_target', message: 'Out of scope' }, 403));

    const error = (await api.health().catch((e: unknown) => e)) as ApiError;
    expect(error.kind).toBe('forbidden');
  });

  it('degrades gracefully when an error response is not JSON', async () => {
    globalThis.fetch = vi
      .fn()
      .mockResolvedValue(new Response('<html>502 Bad Gateway</html>', { status: 502 }));

    const error = (await api.health().catch((e: unknown) => e)) as ApiError;
    expect(error.kind).toBe('server');
    expect(error.code).toBeNull();
  });

  it('classifies a transport failure as a network error', async () => {
    globalThis.fetch = vi.fn().mockRejectedValue(new TypeError('Failed to fetch'));

    const error = (await api.health().catch((e: unknown) => e)) as ApiError;
    expect(error.kind).toBe('network');
  });

  it('raises a server error when a 200 body is not valid JSON', async () => {
    globalThis.fetch = vi
      .fn()
      .mockResolvedValue(
        new Response('not json', { status: 200, headers: { 'Content-Type': 'application/json' } }),
      );

    const error = (await api.health().catch((e: unknown) => e)) as ApiError;
    expect(error.kind).toBe('server');
  });

  it('propagates a caller-initiated abort instead of masking it as a network error', async () => {
    const controller = new AbortController();
    controller.abort();
    globalThis.fetch = vi.fn().mockRejectedValue(new DOMException('Aborted', 'AbortError'));

    const error = (await api.health(controller.signal).catch((e: unknown) => e)) as Error;
    expect(error).not.toBeInstanceOf(ApiError);
    expect(error.name).toBe('AbortError');
  });

  it('clamps the list limit into the query string', async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse([]));
    globalThis.fetch = fetchMock;

    await api.listInvestigations(10);

    expect(fetchMock.mock.calls[0]?.[0]).toBe('http://api.test/investigations?limit=10');
  });
});
