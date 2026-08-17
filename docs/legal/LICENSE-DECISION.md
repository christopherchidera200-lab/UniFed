# UniFed Nigeria — LICENSE Decision (DRAFT)

> **DRAFT — analysis only. NO LICENSE FILE CREATED YET. Final license depends on the business
> model decision requested from the founder (see §6). Do not treat this as a chosen license.**

---

## 1. Current state
- **No LICENSE file exists** in the repository (`git ls-files` returns none).
- Absent a license, the default position under copyright law is **all rights reserved** —
  third parties have no permission to use, modify, or redistribute the code. This is a
  **due-diligence blocker** for OSS grants and for downstream contributors.

## 2. License landscape relevant to UniFed
| Option | Type | Fit for UniFed | Notes |
|--------|------|----------------|-------|
| **MIT** | Permissive OSS | Strong | Simple; allows commercial SaaS; weak copyleft pressure |
| **Apache-2.0** | Permissive OSS | Strong | Adds patent grant + explicit attribution; preferred for grant-funded OSS |
| **AGPL-3.0** | Strong copyleft | Risky for SaaS | Forces source disclosure for network use; can clash with proprietary SaaS plans |
| **Dual (OSS + commercial)** | Mixed | Possible | OSS core + proprietary enterprise add-ons — common for federated platforms |
| **Source-available (no OSS)** | Proprietary | Possible | Maximum control; weaker for OSS-grant alignment |

## 3. Dependency license compatibility (REQUIRES SBOM scan)
- Ruby gems (Rails, etc.) are overwhelmingly MIT/BSD/Apache — compatible with any option above.
- npm packages — must run `license-checker` / `npm ls` to confirm no GPL/AGPL contamination
  if we choose a proprietary or AGPL-averse route. **Not yet scanned.**
- **ActivityPub / federation:** the protocol is open; no licensing constraint on implementing it.
- **Third-party assets (fonts/icons/components):** not yet audited — REQUIRES review.

## 4. Business-model interaction
- The business plan (see `docs/business/BUSINESS_MODEL.md`) contemplates a **commercial SaaS**
  plus white-label/enterprise deployments. A **permissive OSS license (Apache-2.0 recommended)**
  supports both OSS-grant alignment and commercial SaaS, whereas AGPL would constrain proprietary
  features. A **dual-license** (Apache-2.0 core + commercial license for enterprise modules) is
  the strongest fit if some modules stay proprietary.

## 5. Recommendation (pending founder confirmation)
- **Default recommendation: Apache-2.0** for the core platform, with a documented option for a
  commercial/enterprise license on proprietary modules.
- This is **not finalized** — it depends on the founder's answer to the business-model/licensing
  question in `docs/readiness/USER-INFORMATION-REQUIRED.md` (§D).

## 6. Decision required from founder
1. Intended license posture: OSS (which?), source-available, or dual?
2. Any modules intended to remain proprietary (affecting dual-license design)?
3. Confirmation that no contributor agreement conflicts with the chosen license.

**No LICENSE file will be added until these are answered.**
