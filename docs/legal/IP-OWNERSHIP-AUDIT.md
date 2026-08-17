# IP Ownership Audit (DRAFT)

> **DRAFT — engineering/compliance audit. NOT legal advice. Requires review by a qualified
> Nigerian lawyer and confirmation of entity/founder facts before investor/grant due diligence.**

---

## 1. Method

- `git ls-files` enumeration; `git shortlog -sne --all` for authors; SPDX/licence header search;
  third-party dependency inspection (`Gemfile`/`package.json`); check for LICENSE/CLA/CONTRIBUTING.

## 2. Critical finding: NO licence file

The repository contains **no `LICENSE`, `COPYING`, `NOTICE`, or `CONTRIBUTING` file**, and **no
SPDX/copyright headers** in source. Without an explicit licence, default copyright law applies:
**all rights reserved by the respective authors**, and third parties have **no permission to use,
modify, or redistribute** the code. This is a serious gap for open-source claims, grants, and
investors.

## 3. Contributor / commit-author inventory

From `git shortlog -sne --all` (93 commits total):

| Author identity | Commits | Type | IP note |
|---|---|---|---|
| `UniFed Engineering <eng@unifed.ng>` | 65 | Corporate email | Presumed work-for-hire **if** under a UniFed entity + employment/contractor agreement |
| `Hermes Agent <agent@unifed.ng>` | 15 | Tool/agent email | Authored by an AI agent; IP归属 depends on operator + agreements |
| `Christopher Chidera <christopherchidera200@email.com>` | 7 | **Personal Gmail** | **No assignment on record** → ownership not established |
| `chidera christopher <christopherchidera200@gmail.com>` | 3 | **Personal Gmail** | Same person, different name form |
| `CHIDERA OKPALANWOLISA <christopherchidera200@gmail.com>` | 1 | **Personal Gmail** | Same person |
| `CloudIntel <dev@cloudintel.local>` | 2 | Vendor/local | Contractor? No agreement on record |

**Flag:** at least one individual contributed under a **personal email with no IP assignment**.
Until a signed assignment (Phase 5) or confirmation of work-for-hire exists, UniFed cannot assert
clean ownership of those contributions. This is a **due-diligence blocker**.

## 4. AI-assisted / generated code

`Hermes Agent` (15 commits) indicates AI-agent-generated code. AI-generated code's copyright
status is unsettled in many jurisdictions; document the human reviewer/supervisor and retain
evidence of human authorship/curation. Do not claim sole human authorship.

## 5. Third-party / open-source components

- Ruby/Rails ecosystem gems (MIT/BSD/Ruby licences) — list from `Gemfile.lock`.
- Frontend (Next.js) packages — list from `package.json` / `package-lock.json`.
- OSS obligations: attribution (NOTICE), copyleft (if any GPL/AGPL present — must be checked),
  licence compatibility with the chosen UniFed licence.
- **Action:** generate a full third-party licence inventory (`docs/legal/THIRD-PARTY-LICENSES.md`
  — *future*) and scan for copyleft before choosing a UniFed licence.

## 6. Pre-existing / third-party IP

- Any code copied from tutorials/stackoverflow/other repos must be identified and cleared.
- The `project-graveyard` skill and other tooling installed outside the repo are **not** part of
  UniFed IP.

## 7. What must be verified before due diligence

1. The exact **legal entity** that owns UniFed (name, jurisdiction, registration).
2. Founder identities, equity, and founder IP-assignment agreements (Phase 6).
3. Signed **IP assignment** from every contributor, especially personal-email contributors.
4. Contractor/vendor agreements (CloudIntel) with IP-assignment clauses.
5. Chosen **repository licence** +确认 no copyleft conflict.
6. Confirmation of work-for-hire status for `UniFed Engineering` commits.

## 8. Risk rating

- **HIGH** — missing licence + unassigned personal contributions.
- **MEDIUM** — AI-generated code provenance undocumented.
- **MEDIUM** — third-party licence inventory not produced.

See `INTELLECTUAL-PROPERTY-ASSIGNMENT-AGREEMENT-DRAFT.md` and `DUE-DILIGENCE-LEGAL-CHECKLIST.md`.
