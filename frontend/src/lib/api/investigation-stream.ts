/**
 * Typed client for `POST /investigations/stream`.
 *
 * Translates the backend's SSE event sequence into discriminated-union callbacks,
 * so consumers never touch raw frames or parse JSON themselves.
 */
import { ApiError } from './errors';
import { readSseStream } from './sse';
import type {
  ApiErrorBody,
  CollectorResult,
  Investigation,
  InvestigationRequest,
  TargetType,
} from './types';

/** Payload of the `started` event: what the run will attempt. */
export interface InvestigationStarted {
  investigation_id: string;
  target: string;
  target_type: TargetType;
  /** Names of every collector that will run, for rendering pending placeholders. */
  collectors: string[];
}

export interface StreamHandlers {
  onStarted?: (payload: InvestigationStarted) => void;
  onCollector?: (result: CollectorResult) => void;
  onComplete?: (investigation: Investigation) => void;
}

function baseUrl(): string {
  const raw = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:8000';
  return raw.replace(/\/+$/, '');
}

/**
 * Runs a streaming investigation, invoking handlers as events arrive.
 *
 * Resolves when the stream closes. Rejects with an `ApiError` on transport or
 * protocol failure; a deliberate abort propagates the raw `AbortError` so callers
 * can distinguish "user cancelled" from "something broke".
 */
export async function streamInvestigation(
  request: InvestigationRequest,
  handlers: StreamHandlers,
  signal?: AbortSignal,
): Promise<void> {
  let response: Response;

  try {
    response = await fetch(`${baseUrl()}/investigations/stream`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'text/event-stream' },
      body: JSON.stringify(request),
      signal,
      credentials: 'omit',
    });
  } catch (cause) {
    if (signal?.aborted) throw cause;
    throw new ApiError('network', 'Could not open the investigation stream', { cause });
  }

  // Validation failures happen before the stream opens, so they arrive as a normal
  // HTTP error with the standard JSON envelope.
  if (!response.ok) {
    let body: Partial<ApiErrorBody> = {};
    try {
      body = (await response.json()) as ApiErrorBody;
    } catch {
      // Non-JSON error body (proxy error page). Fall back to the status text.
    }
    throw new ApiError(
      ApiError.kindForStatus(response.status),
      body.message ?? response.statusText,
      { status: response.status, code: body.error ?? null },
    );
  }

  for await (const event of readSseStream(response, signal)) {
    // An `error` frame means the run failed after the stream had already opened,
    // so the status line was long gone and this is the only way to report it.
    if (event.event === 'error') {
      const payload = safeParse<ApiErrorBody>(event.data);
      throw new ApiError('server', payload?.message ?? 'The investigation failed', {
        code: payload?.error ?? null,
      });
    }

    switch (event.event) {
      case 'started': {
        const payload = safeParse<InvestigationStarted>(event.data);
        if (payload) handlers.onStarted?.(payload);
        break;
      }
      case 'collector': {
        const payload = safeParse<CollectorResult>(event.data);
        if (payload) handlers.onCollector?.(payload);
        break;
      }
      case 'complete': {
        const payload = safeParse<Investigation>(event.data);
        if (payload) handlers.onComplete?.(payload);
        break;
      }
      default:
        // Unknown event names are ignored rather than fatal, so the backend can
        // add new event types without breaking older clients.
        break;
    }
  }
}

/** Never let one malformed frame tear down an otherwise healthy stream. */
function safeParse<T>(raw: string): T | null {
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}
