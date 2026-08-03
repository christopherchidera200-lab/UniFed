/**
 * Server-Sent Events parsing over `fetch`.
 *
 * The browser's native `EventSource` cannot issue a POST with a JSON body, and an
 * investigation request needs one. So we read the response body stream ourselves
 * and implement the SSE framing rules from the HTML specification:
 * https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
 *
 * The parser is split from the transport so the framing logic is unit-testable
 * without a network or a DOM.
 */

export interface SseEvent {
  /** Value of the `event:` field; defaults to `message` per the spec. */
  event: string;
  /** Concatenated `data:` lines, joined with newlines. */
  data: string;
}

/**
 * Incremental SSE frame parser.
 *
 * Network chunks do not align with event boundaries — a single frame can arrive
 * split across reads, and one read can contain several frames. This buffers until
 * a complete frame (terminated by a blank line) is available.
 */
export class SseParser {
  private buffer = '';

  /** Feeds a chunk of text and returns every complete event it produced. */
  push(chunk: string): SseEvent[] {
    // Normalise line endings first: the spec permits CRLF, CR or LF.
    this.buffer += chunk.replace(/\r\n|\r/g, '\n');

    const events: SseEvent[] = [];
    let boundary = this.buffer.indexOf('\n\n');

    while (boundary !== -1) {
      const frame = this.buffer.slice(0, boundary);
      this.buffer = this.buffer.slice(boundary + 2);

      const parsed = parseFrame(frame);
      if (parsed) events.push(parsed);

      boundary = this.buffer.indexOf('\n\n');
    }

    return events;
  }
}

function parseFrame(frame: string): SseEvent | null {
  let event = 'message';
  const data: string[] = [];

  for (const line of frame.split('\n')) {
    // A leading colon marks a comment (used for heartbeats). Ignore it.
    if (line.startsWith(':')) continue;

    const colon = line.indexOf(':');
    if (colon === -1) continue;

    const field = line.slice(0, colon);
    // A single leading space after the colon is part of the framing, not the value.
    const value = line.slice(colon + 1).replace(/^ /, '');

    if (field === 'event') event = value;
    else if (field === 'data') data.push(value);
  }

  // A frame with no data field dispatches nothing.
  if (data.length === 0) return null;

  return { event, data: data.join('\n') };
}

/**
 * Reads an SSE response body and yields decoded events as they arrive.
 *
 * @throws Error when the response has no readable body.
 */
export async function* readSseStream(
  response: Response,
  signal?: AbortSignal,
): AsyncGenerator<SseEvent> {
  if (!response.body) {
    throw new Error('Response has no readable body');
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  const parser = new SseParser();

  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;

      // stream:true keeps multi-byte UTF-8 sequences intact across chunk boundaries.
      for (const event of parser.push(decoder.decode(value, { stream: true }))) {
        yield event;
      }

      if (signal?.aborted) break;
    }
  } finally {
    // Releasing the lock lets the connection be torn down promptly when the
    // consumer stops early (component unmount, user cancels, new search).
    reader.releaseLock();
  }
}
