# Founder IP & Ownership Readiness (DRAFT)

> **DRAFT — internal readiness checklist. NOT legal advice. Do not invent founder names, ownership
> percentages, or company details. Use placeholders where unknown. Requires legal review.**

---

## 1. Purpose

Capture the corporate/ownership facts investors and grant bodies will demand during due diligence,
and flag what is missing. This does **not** assert any fact about UniFed's structure.

## 2. Information to establish (placeholders — fill from records)

| Item | Status | Placeholder |
|---|---|---|
| Legal entity formed? | UNKNOWN | [YES/NO — entity name, jurisdiction, reg. no.] |
| Entity name | UNKNOWN | [UNIFED LEGAL ENTITY NAME] |
| Founders | UNKNOWN | [FOUNDER 1 NAME], [FOUNDER 2 NAME], … |
| Equity ownership | UNKNOWN | [FOUNDER 1 %], [FOUNDER 2 %], … |
| Cap table | UNKNOWN | [CAP TABLE LOCATION] |
| Founder agreements | UNKNOWN | [EXIST / MISSING] |
| IP assignment (founders) | UNKNOWN | [SIGNED / UNSIGNED] |
| Contractor agreements | UNKNOWN | [CloudIntel etc.] |
| Employee agreements | UNKNOWN | [EXIST / MISSING] |
| Advisor agreements | UNKNOWN | [EXIST / MISSING] |
| Confidentiality / NDA | UNKNOWN | [EXIST / MISSING] |
| Assignment of inventions | UNKNOWN | [EXIST / MISSING] |
| Open-source obligations | PARTIAL | repo has OSS deps; no licence file (see IP-OWNERSHIP-AUDIT) |
| Third-party claims | UNKNOWN | [NONE KNOWN / TBD] |

## 3. Repository evidence (from this audit)

- Commit authors include a personal Gmail identity (`christopherchidera200@gmail.com`) with **no
  assignment** — see `IP-OWNERSHIP-AUDIT.md` §3. Until cleared, founder/developer IP ownership is
  **not established** from repo evidence.
- No `LICENSE` file → default "all rights reserved" until a licence is chosen and applied.

## 4. Why this matters for due diligence

Investors/grants will not proceed without: (a) a clean cap table, (b) IP assigned to the company,
(c) no undisclosed third-party claims, (d) OSS compliance. The missing licence + unassigned
personal contributions are the top blockers.

## 5. Recommended actions

1. Form/confirm the legal entity and record registration.
2. Execute founder agreements with IP-assignment + vesting.
3. Execute IP assignments from all contributors (especially personal-email ones) — use
   `INTELLECTUAL-PROPERTY-ASSIGNMENT-AGREEMENT-DRAFT.md`.
4. Add a repository `LICENSE` + `CONTRIBUTING.md`/CLA (decide licence with counsel).
5. Build a third-party licence inventory and scan for copyleft.

## 6. Status

`NEEDS INFORMATION` + `NEEDS LEGAL REVIEW`. No founder facts are asserted in this document.
