# ADR 0005 — Stream investigation results over Server-Sent Events

- **Status:** Accepted
- **Date:** 2026-08-02
- **Supersedes:** none
- **Related:** ADR 0001 (collector isolation), ADR 0003 (frontend architecture)

## Context

`POST /investigations` runs every applicable collector concurrently with
`asyncio.gather` and returns once all of them settle. Collector isolation already
works — a failing source returns a `CollectorResult` carrying its own error rather
than raising — so one dead source cannot break an investigation.

It can, however, dictate how long the investigation *takes*. `gather` resolves only
when the slowest task does.

Measured against the live internet (`github.com`, blocking endpoint):

| Collector    | Duration | Status  |
| ------------ | -------- | ------- |
| tls          | 0.7s     | ok      |
| dns          | 3.8s     | ok      |
| http         | 1.9s     | ok      |
| whois        | 9.9s     | ok      |
| subdomains   | **15.0s** | timeout |
| **Total**    | **15.0s** | —       |

Four sources produced seven findings within 4s. The user waited 15s to see any of
them, because Certificate Transparency (crt.sh) burned its entire timeout budget.

crt.sh is measurably unreliable from a normal network: three consecutive requests
during development returned `404`, `503`, and a connection timeout. It is also the
only free CT source, so removing it loses genuine signal (subdomain discovery,
including exposed non-production hostnames).

## Decision

Add `POST /investigations/stream`, which emits results incrementally over
Server-Sent Events as each collector settles.

Event sequence:

| Event       | Count | Payload                                              |
| ----------- | ----- | ---------------------------------------------------- |
| `started`   | 1     | investigation id, normalised target, collector names |
| `collector` | 0..n  | one `CollectorResult`, in completion order           |
| `complete`  | 1     | the full scored `InvestigationResponse`              |
| `error`     | 0..1  | only if the run fails after the stream opened        |

The blocking endpoint is retained. Both modes share `_prepare` and `_finalize` in
`app/orchestrator.py`, so validation, collector selection, scoring, and logging
cannot drift between them — a contract test asserts the two agree.

### Why SSE rather than WebSockets

The data flow is strictly server → client. SSE is plain HTTP: no protocol upgrade,
no sticky-session requirement at the load balancer, and automatic browser
reconnection. A WebSocket would add bidirectional machinery this feature does not
use.

### Why validation runs before the stream opens

The first event is pulled eagerly in the endpoint, so `_prepare` executes while the
response status line can still be changed. An invalid target therefore returns a
real `400`/`403` rather than a `200` whose first frame says "error". Once the stream
is open the status is already committed, so later failures are reported in-band as
an `error` event.

## Consequences

**Result (same target, streaming endpoint):**

| Event               | Arrival | Blocking equivalent |
| ------------------- | ------- | ------------------- |
| `started`           | 2.1s    | —                   |
| `tls` ok            | 2.9s    | 15.0s               |
| `dns` ok            | 3.2s    | 15.0s               |
| `http` ok           | 4.1s    | 15.0s               |
| `whois` ok          | 9.2s    | 15.0s               |
| `subdomains` timeout| 17.1s   | 15.0s               |
| `complete`          | 17.1s   | 15.0s               |

Time to first real intelligence: **15.0s → 2.9s**. Total wall-clock is unchanged —
this trades a single long wait for progressive disclosure, which is the honest
framing: we did not make crt.sh faster, we stopped letting it block everything else.

**Costs accepted:**

- Two endpoints to maintain. Mitigated by the shared `_prepare`/`_finalize` core and
  a test asserting both modes produce identical results.
- SSE needs infrastructure cooperation. `X-Accel-Buffering: no` and
  `Cache-Control: no-transform` are set, because a buffering proxy silently degrades
  streaming into a slower blocking request. **This is a hand-off note for the
  infrastructure team: response buffering must be disabled on this route.**
- The client cannot use native `EventSource` (it cannot POST a JSON body), so
  `frontend/src/lib/api/sse.ts` implements the framing rules over `fetch`.

**Cancellation:** if the client disconnects, the async generator is closed and its
`finally` block cancels the still-pending collector tasks, rather than leaving them
running detached.

## Alternatives rejected

- **Shorten the collector timeout.** Would silently drop a source that legitimately
  succeeds sometimes, trading a latency problem for a data-completeness problem.
- **Drop the subdomain collector.** Loses real signal; CT logs are the passive,
  clearly lawful way to discover exposed hostnames.
- **Job queue with polling.** Correct for multi-minute work, disproportionate at
  this scale, and adds storage plus a polling loop for a 3–17s operation.
- **Cache aggressively to hide the latency.** Helps repeat targets only; the first
  investigation of any target — the one that forms the user's impression — is unchanged.
