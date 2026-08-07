# ADR-0004: Authentication & Identity

- **Status:** Accepted
- **Date:** 2026-08-06

## Context

UniFed must support students, lecturers, staff, and admins across universities, with integration
to existing ADUN systems (ASIS student portal, SPGS, ICT Directorate SSO). Security-by-design and
MFA are mandated.

## Decision

- **Primary:** OAuth2 + OpenID Connect (OIDC). The platform is its own OIDC Provider (OP) and can
  also act as a Relying Party to ADUN's existing SSO where the ICT Directorate exposes it.
- **MFA:** TOTP (RFC 6238) + WebAuthn (FIDO2) as second factors. Required for staff/admin roles.
- **Student linking:** A `StudentIdentity` links an OIDC account to a `Student` academic record via
  matric number + one-time verification token issued by the Registry context.
- **Passwords:** Argon2id, never reused across contexts; breach-checked at enrollment.
- **Sessions:** Opaque signed session tokens; refresh tokens rotated;Redis-backed revocation.

## Consequences

- Identity context owns auth; other contexts request `subject` claims, never passwords.
- Integrates with ASIS/SPGS once ICT Directorate shares the SSO spec (⚠️ open gap in brief).
