# STRIX Executive Summary — UniFed Nigeria Security Assessment

> Prepared for: Christopher Chidera (Founder/CEO, UniFed Nigeria) and pilot stakeholders.
> Date: 2026-08-15 · Type: Authorized penetration test (our own system, pre-pilot).

## Bottom line

We performed an authorized security test of the UniFed platform (the Rails backend, the Next.js app, and our local staging environment). The codebase is **fundamentally sound** — automated scanning found **no code-level vulnerabilities** (no SQL injection, no cross-site scripting, no broken access in the academic/identity code), and the app enforces login correctly with strong security headers.

**However, we found one CRITICAL issue that must be fixed before the pilot goes live:** the system's login tokens can currently be **forged by anyone who knows a secret that is sitting in our own configuration**. We proved this in a controlled test — we were able to create a valid "admin" login token from scratch, with no password, and the system accepted it. This is fixable with a small, safe code change (already written) plus setting a strong secret in our hosting panel.

## What we found (by severity)

| Severity | Count | Headline |
|---|---|---|
| 🔴 Critical | 1 | Login tokens can be forged → full account takeover / admin impersonation |
| 🟠 High | 1 | Login tokens lack an "audience" check (weaker than best practice) |
| 🟡 Medium | 8 | Rate-limiting can be bypassed; federation not production-hardened; database/Redis ports exposed in dev config; a couple of "return/acknowledge" actions don't check ownership; weak default secrets |
| 🟢 Low | 2 | Minor "mark-as-read" ownership gap; outdated developer-only tooling libraries |

## The one thing to act on now (Critical)

- **What:** The signing secret for login tokens defaults to a value that is committed in our repository. On our current staging stack that default is in use.
- **Proof:** Using that known value, we forged an admin token and the server returned a normal authenticated response (vs. "unauthorized" without a token).
- **Fix (two parts):**
  1. **Code (done):** the app now refuses to run with a weak/missing token secret — it fails closed instead of silently using an insecure default.
  2. **Operations (you/us in Coolify):** set a strong, random `OIDC_JWKS_PRIVATE` (and `SECRET_KEY_BASE`) in the hosting secrets; rotate if the weak value was ever used.

## What's already good (don't regress)

- Login is required on every protected screen; unauthenticated requests are rejected.
- Student academic records and digital student-ID actions correctly check that you belong to the right university and role.
- Security headers (HTTPS enforcement, content policies, frame protection) are properly set.
- Automated code scanning: **zero warnings**.

## Recommended next steps

1. **Before pilot:** apply the Critical fix + set strong hosting secrets. (Blocking.)
2. **Before pilot:** close the Medium items that affect real abuse (rate-limit bypass, lock down database/Redis exposure, fix the two ownership checks on library/notifications).
3. **Hardening:** finish the federation (university-to-university) security work (replay protection, signature verification) before enabling cross-university federation.
4. **Ongoing:** keep the automated scanners in CI so new issues are caught on every change.

## Security score

**6.5 / 10** — strong code hygiene and authz design, dragged down by one Critical configuration/secret-management gap that is cheap to fix. After the Critical + Medium remediations: **8.5 / 10**.

*Detailed technical findings, proof-of-concept evidence, and the full fix plan are in the companion documents (STRIX-FINDINGS.md, STRIX-PENTEST-REPORT.md, STRIX-REMEDIATION-PLAN.md, STRIX-TEST-MATRIX.md).*
