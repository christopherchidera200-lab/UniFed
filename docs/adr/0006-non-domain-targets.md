# ADR 0006 — Non-domain investigation targets

- **Status:** Accepted
- **Date:** 2026-08-03
- **Supersedes:** none
- **Related:** ADR 0001 (collector isolation), ADR 0005 (streaming)

## Context

Phase 0 shipped the investigation workspace for **domains only**: five collectors
(forward DNS, RDAP-less WHOIS, TLS, HTTP, subdomains), all declaring
`supported_types = (DOMAIN,)`. The UI, however, already offered IP / email /
username as selectable target types — and selecting one returned an *empty*
investigation, because the orchestrator's `registry.select()` found no applicable
collector and raised `InvalidTarget`. That was a silent, broken state, not a
polite "unsupported".

The validation, orchestration, scoring, and streaming layers are all
**target-type-agnostic** — they operate on `TargetType` and a list of
collectors, never on domain-specific logic. So extending coverage was purely a
matter of adding collectors that declare the right `supported_types`; everything
downstream auto-wires.

## Decision

Add four collectors, all free, key-less, and lawfully public:

| Collector | Types | Source | Legal posture |
|---|---|---|---|
| `rdap` | ip, domain | Regional internet registries via RDAP (RFC 7482/7483) | Registration data is published by design — the IETF-standard successor to WHOIS |
| `reverse-dns` | ip | DNS PTR (dnspython, public resolvers) | PTR is public DNS, queried by anyone |
| `email-domain` | email | DNS MX + RDAP of the domain half | Only the domain portion is investigated; the mailbox/local part is never probed |
| `username-presence` | username | GitHub + dev.to public profile GETs | One unauthenticated GET per platform; only the fact of a profile's existence is recorded |

**Username scope (deliberately narrow):** GitHub + dev.to only. Both verified to
return a clean 200 (present) / 404 (absent) on a plain GET with no API key. We
explicitly do **not** scrape private data, enumerate associated accounts, or use
any "data broker" / breach source. Presence on two independent platforms is
treated as corroborated (slightly higher severity). The `_SOURCES` list is the
documented extension point for adding more platforms later.

**Email scope (deliberately narrow):** the email collector investigates the
*domain* half — MX records and RDAP registration — reusing the same public
signals as a domain investigation. It never performs SMTP probing, account
enumeration, or breach lookups. This is both the lawful boundary and the
highest-value signal an email address legitimately exposes.

## Consequences

All four target types now return findings against the live internet (verified):

| Target | Collectors fired | Sample findings |
|---|---|---|
| `8.8.8.8` | rdap, reverse-dns | IP registration record, reverse DNS hostname |
| `analyst@example.com` | email-domain | MX routing, domain registration |
| `octocat` | username-presence | claimed on GitHub + dev.to (corroborated) |
| `github.com` | dns, rdap, subdomains, tls, whois, http | unchanged, plus the new `rdap` domain findings |

Frontend changes were minimal and mostly cosmetic: per-type input placeholder and
a one-line hint naming what each type accepts, because `TARGET_TYPES` and the
`CollectorInfo.supported_types` contract already anticipated all four types.

## Tests added

- `test_new_collectors.py` — collector behaviour with `respx`-mocked sources:
  RDAP IP/domain handling, reserved-allocation flag, expiry detection, 404 empty;
  reverse-DNS present/absent; email domain-half (and that the local part is never
  probed); username presence on one/two/none sources and graceful source failure.
- `test_target_coverage.py` — contract lock: every `TargetType` has applicable
  collectors, and the set matches the minimum expectation. (This is the regression
  guard for the original empty-investigation bug.)
- Frontend `e2e/multi-target.spec.ts` (mocked SSE) + `e2e/live-ip.spec.ts` (real
  backend) prove the full stack end-to-end for non-domain types.

## Alternatives considered

- **Keep it domain-only and disable the other type buttons.** Rejected: the UI
  already advertised the capability, and the architecture made the extension cheap
  and safe. Hiding it would be dishonest about the product's intent.
- **Add a wider username scraper (Reddit, Twitter, Instagram, LinkedIn).** Of
  those, only GitHub and dev.to returned a clean 200/404 on an unauthenticated GET
  during development; the others returned 403/blocked. Scraping them would mean
  fighting anti-bot defences and drifting toward grey-area collection. Deferred to
  a later phase with explicit per-platform review.
- **Probe the mailbox for email targets (SMTP, breach corpora).** Rejected as
  out of scope and unlawful without authorization; it is also low-signal compared
  to the domain posture we already collect.
