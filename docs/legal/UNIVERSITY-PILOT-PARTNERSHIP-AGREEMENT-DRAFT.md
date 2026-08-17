# University Pilot Partnership Agreement — DRAFT

> **DRAFT — FOR LEGAL REVIEW — NOT FOR SIGNATURE**
> Prepared by the UniFed engineering/documentation team. This is a template, not legal advice.
> All `[PLACEHOLDER]` fields must be completed and the document reviewed by a qualified
> Nigerian lawyer before execution.

---

## Parties

**1.1** **[UNIFED LEGAL ENTITY NAME]** ("**UniFed**"), a [COMPANY TYPE] registered in
[REGISTRATION STATE/COUNTRY], with registered address at [UNIFED REGISTERED ADDRESS], represented
by [UNIFED AUTHORISED SIGNATORY NAME], [TITLE].

**1.2** **[UNIVERSITY LEGAL NAME]** ("**the University**"), a [FEDERAL/STATE] university
established under [ESTABLISHING LAW / EDICT], with principal address at [UNIVERSITY ADDRESS],
represented by [UNIVERSITY AUTHORISED SIGNATORY NAME], [TITLE] (e.g., Vice-Chancellor).

UniFed and the University are each a "**Party**" and together the "**Parties**".

> *Note: The UniFed legal entity name is NOT established in the repository. Do not invent it.
> The pilot university is Admiralty University of Nigeria (ADUN) per project context; insert its
> full legal name and address as [UNIVERSITY LEGAL NAME] / [UNIVERSITY ADDRESS].*

---

## 2. Purpose of the pilot

To deploy a UniFed instance for the University as a federated Digital University Operating System,
enabling the University to operate its own independent instance while connecting to other
university instances through ActivityPub federation, for the purposes of [PILOT OBJECTIVES].

## 3. Scope of services

UniFed will provide: the UniFed software (self-hosted instance or managed instance), configuration,
integration support, and pilot-period maintenance, as detailed in **Appendix A**.

## 4. Pilot duration

The pilot commences on **[EFFECTIVE DATE]** and continues for **[PILOT PERIOD]** ("**Pilot
Period**"), unless extended in writing or terminated under Clause 31.

## 5. Roles and responsibilities

See **Appendix D** for the allocation of support and service responsibilities.

## 6. University responsibilities

- Provide [UNIVERSITY ADDRESS] contact, infrastructure access, and authorised data sources.
- Designate a pilot coordinator and authorised signatory.
- Obtain any internal approvals, ethics/Data Protection Impact Assessment (DPIA) clearances, and
  student/staff consent as required under NDPA 2023.
- Maintain the security of its instance credentials and administrative accounts.

## 7. UniFed responsibilities

- Deploy and configure the UniFed instance per Appendix A.
- Provide pilot-period support, security updates, and bug fixes.
- Carry out the security remediations documented in `docs/security/STRIX-REMEDIATION-LOG.md`.
- Notify the University of security incidents per Clause 18.

## 8. Student / user onboarding

Onboarding of students, staff, and administrators shall follow the University's admission and
HR processes. UniFed shall provide onboarding tooling but the University remains the
**data controller** for personal data it loads (see Clauses 9–13). Consent capture mechanisms
shall be configured per `PRIVACY-POLICY-DRAFT.md`.

## 9. Data ownership and control

**9.1** The University retains ownership and control of University Data (defined in Appendix B),
including student identity, academic records, results, transcripts, and University content.

**9.2** UniFed does not claim ownership of University Data. UniFed is a processor/provider as
defined per Clause 10, subject to verification by counsel.

## 10. Data processing responsibilities

**10.1** Each Party's role (controller / processor / joint controller) is a **legal question
requiring confirmation** and may differ by data category (see `DATA-PROTECTION-READINESS.md`).

**10.2** Where UniFed processes personal data on the University's behalf, it shall do so only on
documented instructions, with appropriate technical/organisational measures (Clause 16), and shall
assist the University with data-subject requests (Clause 12, `DATA-SUBJECT-REQUEST-PROCEDURE.md`).

## 11. Academic records

Academic records (results, transcripts, assessments) are University Data. UniFed stores and
processes them solely to provide the service. Integrity, grading authority, and certification
remain with the University.

## 12. Student identity information

Student digital identity, profiles, and authentication data are University Data. UniFed provides
the identity service but the University controls the accounts.

## 13. Federated data

**13.1** Federation via ActivityPub transmits actor metadata and user-generated content to other
instances. Federation does **not** transfer ownership of University Data.

**13.2** The University controls which data categories are eligible for federation (Appendix E).
UniFed shall provide controls to restrict federation scope.

## 14. ActivityPub interoperability

The Parties acknowledge that interoperability depends on conformant ActivityPub behaviour.
UniFed shall implement identity verification and impersonation controls per `FEDERATION-POLICY-DRAFT.md`.

## 15. Data sharing between university instances

Cross-instance data sharing occurs only via federation controls configured by each instance.
No University Data is shared outside the federation scope without the University's instruction.

## 16. Security obligations

UniFed shall maintain the safeguards in `DATA-PROTECTION-READINESS.md` (Appendix C) and the
remediations in the STRIX log. The University shall secure its administrators, credentials, and
network.

## 17. Access control

Role-based access control, MFA, and session management are provided by UniFed. The University
assigns roles and is responsible for privileged-account hygiene.

## 18. Incident / security breach handling

On becoming aware of a personal-data breach, UniFed shall notify the University without undue
delay and cooperate on NDPA notification (72 hours where applicable) per
`DATA-BREACH-RESPONSE-PROCEDURE.md`.

## 19. Data retention

Retention periods follow `DATA-RETENTION-POLICY-DRAFT.md` and University policy. UniFed shall
apply retention controls where technically supported.

## 20. Data deletion / return at termination

On termination, UniFed shall, at the University's election, return University Data in a
portable format and/or delete it, and certify deletion, subject to legal retention obligations.
Federated copies already propagated to other instances are addressed in Clause 13 / Appendix E.

## 21. Intellectual property

Subject to Clauses 22–25, each Party retains its pre-existing IP. No licence is granted except as
expressly stated.

## 22. Software ownership

UniFed software is owned by [UNIFED LEGAL ENTITY NAME] or its licensors. Licence to the University
for the Pilot is non-exclusive, non-transferable, revocable on termination.

## 23. University-owned content / data

University Data and University-created content remain the University's property.

## 24. Third-party software

The software incorporates third-party open-source components; licence obligations (attribution,
copyleft) are listed in `IP-OWNERSHIP-AUDIT.md`.

## 25. Open-source components

UniFed's OSS obligations survive. The University shall not be required to disclose its own
confidential University Data.

## 26. Confidentiality

Each Party shall protect the other's confidential information and use it only for the Pilot.
Survives termination for [CONFIDENTIALITY PERIOD].

## 27. Acceptable use

The University and its users shall comply with `ACCEPTABLE-USE-POLICY-DRAFT.md` and
`COMMUNITY-GUIDELINES-DRAFT.md`.

## 28. Service availability / limitations

Target availability: [SLA %]. The Pilot is provided "as is" for evaluation; no warranty of
uninterrupted service beyond Appendix D.

## 29. Liability

**[LIMITATION OF LIABILITY — FOR LEGAL REVIEW]** Liability is excluded/limited to the extent
permitted by Nigerian law. Do not finalise without counsel.

## 30. Indemnity

**[INDEMNITY — FOR LEGAL REVIEW]** Mutual/one-way indemnities to be drafted by counsel.

## 31. Termination

Either Party may terminate on [NOTICE PERIOD] notice, or immediately on material breach or
regulatory order.

## 32. Post-pilot transition

On successful pilot, the Parties may execute a production agreement on terms to be agreed. Data
portability per Clause 20 applies.

## 33. Expansion beyond pilot

Expansion to additional faculties or to federation with other universities requires a superseding
agreement and DPIA.

## 34. Publicity / branding

Neither Party uses the other's name/marks without prior written consent.

## 35. Research / data use restrictions

UniFed shall not use University Data for model training or research without separate consent and
agreement.

## 36. Dispute resolution

**[DISPUTE RESOLUTION — FOR LEGAL REVIEW]** (e.g., negotiation → mediation → arbitration under
[AIMA / Lagos Court of Arbitration]).

## 37. Governing law

**[GOVERNING LAW — PLACEHOLDER]** This Agreement is governed by the laws of the Federal Republic of
Nigeria. *Confirm with counsel; do not treat as final.*

## 38. Notices

Notices to [UNIFED NOTICE ADDRESS] and [UNIVERSITY NOTICE ADDRESS].

## 39. Entire agreement

This Agreement (with Appendices) is the entire agreement on its subject matter.

## 40. Amendments

Only by written instrument signed by both Parties.

## 41. Signature blocks

| UniFed | University |
|---|---|
| Signature: ____________________ | Signature: ____________________ |
| Name: [UNIFED AUTHORISED SIGNATORY NAME] | Name: [UNIVERSITY AUTHORISED SIGNATORY NAME] |
| Title: [TITLE] | Title: [TITLE] |
| Date: ____________________ | Date: ____________________ |

---

## Appendix A — Pilot Scope
[PILOT SCOPE: modules enabled, instance model (self-hosted vs managed), integrations, go-live criteria]

## Appendix B — Data Categories
See `DATA-PROTECTION-READINESS.md` §Data categories. Student identity, academic records,
results, transcripts, digital identity, profiles, communications, career, library, events,
assignments, content, federated data.

## Appendix C — Technical / Security Controls
See `LEGAL-TO-TECHNICAL-CONTROL-MATRIX.md` and `DATA-PROTECTION-READINESS.md`.

## Appendix D — Support & Service Responsibilities
[Support tiers, response times, escalation, on-call]

## Appendix E — Federation Scope
See `FEDERATION-POLICY-DRAFT.md`. Eligible data categories, blocking/defederation, identity verification.
