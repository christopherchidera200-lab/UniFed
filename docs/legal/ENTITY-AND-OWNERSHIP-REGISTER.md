# UniFed Nigeria — Entity & Ownership Register (DRAFT)

> **DRAFT — status reflects repository evidence only. No company/ownership facts invented.
> Classification: CONFIRMED / UNCONFIRMED / REQUIRES DOCUMENTATION.**
> This register does NOT establish legal ownership — it records what the repository can prove.

---

## 1. Legal entity
| Field | Value | Status |
|-------|-------|--------|
| Legal entity name | — | **UNCONFIRMED** — not present in repo |
| CAC registration | — | **UNCONFIRMED** — no `CAC`/`BN`/`RC` number in repo |
| Registered address | — | **UNCONFIRMED** |
| Entity type (Ltd / LLP / trust) | — | **UNCONFIRMED** |

## 2. Founders / shareholders / directors
| Person | Role | Status | Evidence |
|--------|------|--------|----------|
| Christopher Chidera | Founder/CEO (per user profile & docs) | **UNCONFIRMED in repo** | Named in README; no incorporation doc |
| Co-founders | — | **UNCONFIRMED** | None identified in repo |
| Directors | — | **UNCONFIRMED** | None in repo |
| Beneficial owners | — | **UNCONFIRMED** | None in repo |

## 3. Project / IP owner
| Item | Value | Status |
|------|-------|--------|
| Project owner | UniFed Nigeria (project name) | **UNCONFIRMED** as legal owner |
| IP owner of codebase | — | **REQUIRES DOCUMENTATION** (assignment/entity) |
| Trademark "UniFed" | — | **UNCONFIRMED** |

## 4. Development contributors (from git history)
Git history shows **mixed commit identities** (observed earlier in audit): corporate-style
author emails and at least one personal Gmail address. Specific contributor list:
| Contributor type | Present? | Status |
|------------------|----------|--------|
| Core developer(s) | Yes (mixed identities) | **CONFIRMED present, identity UNVERIFIED** |
| Co-founders as contributors | Unknown | **UNCONFIRMED** |
| Contractors / freelancers | Unknown | **REQUIRES USER INPUT** |
| AI coding agents (Hermes/Claude) | Likely used (per user) | **REQUIRES USER INPUT** — agents do NOT own IP; human/legal owner must be established |
| Students / external devs | Unknown | **REQUIRES USER INPUT** |

## 5. Third-party / open-source dependencies
| Item | Status |
|------|--------|
| Ruby/Rails + gems | Present (Gemfile) — licenses to be enumerated (see LICENSE-DECISION) |
| Next.js + npm packages | Present (package.json) — licenses to be enumerated |
| No proprietary/commercial licensed component identified yet | **PARTIAL** — full SBOM/license scan REQUIRED |

## 6. Existing commercial/licenses
| Item | Status |
|------|--------|
| Existing IP assignment agreements | **NONE in repo** — REQUIRES DOCUMENTATION |
| Commercial licenses held | **UNCONFIRMED** |
| University-owned resources/code/branding | **REQUIRES USER INPUT** (esp. ADUN pilot assets) |

## 7. Conclusion
The repository **cannot confirm** a legal entity, ownership, or executed IP assignments.
These are **hard blockers** for investment and grant due diligence and must be resolved by
the founder (see `docs/readiness/USER-INFORMATION-REQUIRED.md`). Until then, IP ownership is
**UNCONFIRMED** and should not be represented as established.
