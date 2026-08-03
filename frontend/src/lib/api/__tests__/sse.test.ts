import { describe, expect, it } from 'vitest';
import { SseParser, readSseStream } from '../sse';

describe('SseParser', () => {
  it('parses a single complete frame', () => {
    const events = new SseParser().push('event: collector\ndata: {"a":1}\n\n');
    expect(events).toEqual([{ event: 'collector', data: '{"a":1}' }]);
  });

  it('defaults the event name to "message" when no event field is present', () => {
    expect(new SseParser().push('data: hello\n\n')).toEqual([
      { event: 'message', data: 'hello' },
    ]);
  });

  it('parses several frames arriving in one chunk', () => {
    const events = new SseParser().push(
      'event: a\ndata: 1\n\nevent: b\ndata: 2\n\n',
    );
    expect(events.map((e) => e.event)).toEqual(['a', 'b']);
  });

  it('buffers a frame split across chunk boundaries', () => {
    // The critical real-network case: TCP chunks do not respect event boundaries.
    const parser = new SseParser();
    expect(parser.push('event: collec')).toEqual([]);
    expect(parser.push('tor\ndata: {"x"')).toEqual([]);
    expect(parser.push(':1}\n\n')).toEqual([{ event: 'collector', data: '{"x":1}' }]);
  });

  it('does not emit an incomplete trailing frame', () => {
    const parser = new SseParser();
    expect(parser.push('event: a\ndata: 1\n\nevent: b\ndata: par')).toHaveLength(1);
  });

  it('joins multi-line data fields with newlines', () => {
    expect(new SseParser().push('data: line1\ndata: line2\n\n')).toEqual([
      { event: 'message', data: 'line1\nline2' },
    ]);
  });

  it('ignores comment frames used as heartbeats', () => {
    const events = new SseParser().push(': heartbeat\n\nevent: a\ndata: 1\n\n');
    expect(events).toEqual([{ event: 'a', data: '1' }]);
  });

  it('ignores a frame that carries no data field', () => {
    expect(new SseParser().push('event: ping\n\n')).toEqual([]);
  });

  it('normalises CRLF and CR line endings', () => {
    expect(new SseParser().push('event: a\r\ndata: 1\r\n\r\n')).toEqual([
      { event: 'a', data: '1' },
    ]);
  });

  it('strips exactly one leading space after the colon', () => {
    // Per spec, "data:  x" (two spaces) keeps the second space.
    expect(new SseParser().push('data:  x\n\n')[0]?.data).toBe(' x');
  });
});

/** Builds a Response whose body streams the given chunks. */
function streamingResponse(chunks: string[]): Response {
  const encoder = new TextEncoder();
  const body = new ReadableStream<Uint8Array>({
    start(controller) {
      for (const chunk of chunks) controller.enqueue(encoder.encode(chunk));
      controller.close();
    },
  });
  return new Response(body, { headers: { 'Content-Type': 'text/event-stream' } });
}

describe('readSseStream', () => {
  it('yields every event across chunk boundaries', async () => {
    const response = streamingResponse(['event: a\ndata: 1\n', '\nevent: b\ndata: 2\n\n']);

    const seen: string[] = [];
    for await (const event of readSseStream(response)) seen.push(event.event);

    expect(seen).toEqual(['a', 'b']);
  });

  it('throws when the response has no body', async () => {
    const bodiless = new Response(null, { status: 204 });
    await expect(async () => {
      for await (const _ of readSseStream(bodiless)) {
        // no-op
      }
    }).rejects.toThrow('no readable body');
  });

  it('stops reading once the signal is aborted', async () => {
    const controller = new AbortController();
    const response = streamingResponse([
      'event: a\ndata: 1\n\n',
      'event: b\ndata: 2\n\n',
    ]);

    const seen: string[] = [];
    for await (const event of readSseStream(response, controller.signal)) {
      seen.push(event.event);
      controller.abort();
    }

    expect(seen).toEqual(['a']);
  });
});
