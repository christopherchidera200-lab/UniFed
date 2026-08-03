"""Server-Sent Events transport.

SSE rather than WebSockets: the data flow is strictly server -> client, SSE is plain
HTTP (no upgrade, no sticky-session requirement at the load balancer), and browsers
reconnect automatically. A WebSocket would add bidirectional machinery we do not need.

Wire format (https://html.spec.whatwg.org/multipage/server-sent-events.html):

    event: collector\\n
    data: {"collector": "dns", ...}\\n
    \\n

Every payload is single-line JSON, so the multi-line ``data:`` folding rules never
apply. ``format_sse`` still splits on newlines defensively — a stray newline would
otherwise truncate the event and desynchronise the client's parser.
"""
from __future__ import annotations

import json
from typing import Any

# Comment frame. Emitted as a keep-alive: proxies that buffer or time out idle
# connections see bytes without the client parsing an event.
HEARTBEAT = ": heartbeat\n\n"


def format_sse(event: str, data: Any) -> str:
    """Serialise one SSE frame.

    Args:
        event: Event name the client listens for.
        data: JSON-serialisable payload. Pydantic models must be dumped by the caller.
    """
    payload = json.dumps(data, separators=(",", ":"), default=str)
    lines = "\n".join(f"data: {line}" for line in payload.split("\n"))
    return f"event: {event}\n{lines}\n\n"


# Headers required for SSE to survive real-world infrastructure.
#   Cache-Control          — never cache an event stream.
#   X-Accel-Buffering: no  — tells nginx not to buffer, which would defeat streaming
#                            entirely by holding events until the response closed.
#   Connection: keep-alive — explicit for HTTP/1.1 intermediaries.
SSE_HEADERS = {
    "Cache-Control": "no-cache, no-transform",
    "Connection": "keep-alive",
    "X-Accel-Buffering": "no",
}
