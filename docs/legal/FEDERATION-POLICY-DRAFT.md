# Federation Policy (DRAFT)

> **DRAFT — REQUIRES REVIEW BY QUALIFIED NIGERIAN LAWYER / FEDERATION GOVERNANCE**
> Core differentiator of UniFed. ActivityPub federation does **NOT** transfer ownership of
> university/student data.

---

## 1. Independent instances

Each university operates its own UniFed instance, its own data controller, and its own rules.

## 2. Federation participation

Instances federate voluntarily, by mutual configuration. Federation exchanges actor metadata and
user-generated content per each instance's scope.

## 3. Data exchanged

Only configured data categories are federated (default: public actor/profile + explicitly shared
content). Academic records, results, transcripts, and private student data are **not** federated by
default.

## 4. User-generated content

Content authored on an instance remains owned by its author/university. Federation is a copy for
interoperability, not a transfer of ownership.

## 5. Moderation responsibilities

Each instance moderates its own content and users. Federated content visible on an instance is
subject to that instance's AUP/Community Guidelines.

## 6. Blocking / suspension / defederation

An instance may block, suspend, or fully defederate another for abuse, impersonation, or breach.
Defederation stops new exchange; already-propagated copies are addressed per the DSR/breach
procedures (best-effort removal/withdrawal).

## 7. Abuse reporting

Cross-instance abuse is reported to the originating instance's abuse contact and, if needed, the
receiving instance's moderator.

## 8. Security incidents

A breach at one instance that affects federated data is handled per `DATA-BREACH-RESPONSE-PROCEDURE.md`,
with notification to affected instances.

## 9. Impersonation & identity verification

Instances should verify actor identity (the code implements signature verification + SSRF guards).
Impersonation is prohibited; affected instances may block/defederate.

## 10. Academic credential information

Transcripts/credentials are shared via signed, verifiable mechanisms (JWKS-signed JWTs), not open
federation. Verification endpoints are separate from social federation.

## 11. Privacy boundaries

Federation must respect consent withdrawal and data-subject requests; erasure may not fully purge
already-federated copies — coordinate per `DATA-SUBJECT-REQUEST-PROCEDURE.md`.

## 12. University authority

Each university controls its instance's federation scope, blocks, and participation.

## 13. Cross-instance requests

Cross-instance reads/writes follow each instance's API terms and authentication.

## 14. Federation termination

On termination, exchange stops; each instance retains its own data per its retention policy.
