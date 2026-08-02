/**
 * Typed HTTP client for the CloudIntel API.
 *
 * Responsibilities (and nothing else):
 *   - build the request,
 *   - enforce a client-side timeout,
 *   - normalise every failure into an ApiError,
 *   - hand back a typed body.
 *
 * Caching, retries and React state live in the hooks layer, not here.
 */
import { ApiError } from './errors';
import type {
  CollectorInfo,
  HealthResponse,
  Investigation,
  InvestigationRequest,
  InvestigationSummary,
} from './types';

const DEFAULT_TIMEOUT_MS = 45_000;

function baseUrl(): string {
  const raw = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:8000';
  return raw.replace(/\/+$/, '');
}

interface RequestOptions {
  method?: 'GET' | 'POST';
  body?: unknown;
  signal?: AbortSignal;
  timeoutMs?: number;
}

async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { method = 'GET', body, signal, timeoutMs = DEFAULT_TIMEOUT_MS } = options;

  const timeoutController = new AbortController();
  const timer = setTimeout(() => timeoutController.abort(), timeoutMs);

  // Honour both the caller's cancellation and our own timeout.
  const signals = signal ? [signal, timeoutController.signal] : [timeoutController.signal];

  let response: Response;
  try {
    response = await fetch(`${baseUrl()}${path}`, {
      method,
      headers: body ? { 'Content-Type': 'application/json' } : undefined,
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.any(signals),
      credentials: 'omit',
    });
  } catch (cause) {
    clearTimeout(timer);
    // The caller aborted deliberately - propagate so React can ignore it.
    if (signal?.aborted) throw cause;
    if (timeoutController.signal.aborted) {
      throw new ApiError('timeout', 'Request timed out', { cause });
    }
    throw new ApiError('network', 'Network request failed', { cause });
  }
  clearTimeout(timer);

  if (!response.ok) {
    throw new ApiError(ApiError.kindForStatus(response.status), await extractMessage(response), {
      status: response.status,
      code: await extractCode(response),
    });
  }

  if (response.status === 204) return undefined as T;

  try {
    return (await response.json()) as T;
  } catch (cause) {
    throw new ApiError('server', 'Malformed response from the API', { cause });
  }
}

/**
 * Reads the backend's `{ error, message }` envelope. Response bodies can only be
 * consumed once, so both helpers operate on a clone.
 */
async function extractMessage(response: Response): Promise<string> {
  try {
    const body = (await response.clone().json()) as { message?: unknown };
    return typeof body.message === 'string' ? body.message : response.statusText;
  } catch {
    return response.statusText;
  }
}

async function extractCode(response: Response): Promise<string | null> {
  try {
    const body = (await response.clone().json()) as { error?: unknown };
    return typeof body.error === 'string' ? body.error : null;
  } catch {
    return null;
  }
}

export const api = {
  health: (signal?: AbortSignal) => request<HealthResponse>('/health', { signal }),

  collectors: (signal?: AbortSignal) => request<CollectorInfo[]>('/collectors', { signal }),

  createInvestigation: (payload: InvestigationRequest, signal?: AbortSignal) =>
    request<Investigation>('/investigations', { method: 'POST', body: payload, signal }),

  listInvestigations: (limit = 25, signal?: AbortSignal) =>
    request<InvestigationSummary[]>(`/investigations?limit=${encodeURIComponent(limit)}`, {
      signal,
    }),

  getInvestigation: (id: string, signal?: AbortSignal) =>
    request<Investigation>(`/investigations/${encodeURIComponent(id)}`, { signal }),
};
