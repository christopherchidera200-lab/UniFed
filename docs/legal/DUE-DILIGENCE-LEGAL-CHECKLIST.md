# Investor / Grant Due-Diligence Legal Checklist (DRAFT)

> **DRAFT — internal checklist. NOT legal advice. Tick items only after verified by counsel/admins.**
> Sources: `IP-OWNERSHIP-AUDIT.md`, `FOUNDER-IP-AND-OWNERSHIP-READINESS.md`, `DATA-PROTECTION-READINESS.md`.

---

## Corporate
- [ ] Certificate of incorporation / registration ([UNIFED LEGAL ENTITY NAME], jurisdiction, reg no.)
- [ ] Founders identified with roles ([FOUNDER 1], [FOUNDER 2], …)
- [ ] Equity / cap table documented and signed
- [ ] Founder agreements (IP assignment + vesting)
- [ ] Board/shareholder resolutions where required

## IP
- [ ] IP ownership established (no unassigned personal contributions)
- [ ] Developer IP assignments signed (use `INTELLECTUAL-PROPERTY-ASSIGNMENT-AGREEMENT-DRAFT.md`)
- [ ] Contractor/vendor assignments (CloudIntel, etc.)
- [ ] Repository `LICENSE` file chosen + applied
- [ ] Third-party / OSS licence inventory produced; no copyleft conflict
- [ ] AI-generated code provenance documented
- [ ] No undisclosed third-party IP claims

## Data
- [ ] Privacy Policy (NDPA-aligned) — `PRIVACY-POLICY-DRAFT.md`
- [ ] NDPA readiness / DPIA completed before pilot
- [ ] Data processing agreements with sub-processors (hosting, email)
- [ ] Consent mechanism functional (FIXED this turn) + version/timestamp
- [ ] Security controls (STRIX remediation) evidenced
- [ ] Data retention policy + enforcement
- [ ] Incident response runbook (72h NDPA notification)

## Commercial
- [ ] University pilot agreement executed — `UNIVERSITY-PILOT-PARTNERSHIP-AGREEMENT-DRAFT.md`
- [ ] Customer / partnership agreements template
- [ ] Vendor agreements

## Technology
- [ ] Source-code ownership (assignment) confirmed
- [ ] Security audit report (`docs/security/STRIX-*`)
- [ ] Infrastructure ownership (cloud accounts, domains, repo) documented
- [ ] Domain ownership ([unifed.ng] etc.)
- [ ] Cloud accounts ownership + access control
- [ ] Repository ownership (GitHub org) confirmed

## Status

`NEEDS INFORMATION` across Corporate/IP/Commercial. Top blockers: **missing repo licence**,
**unassigned personal contributions**, **no executed pilot agreement**, **DPIA not done**.
