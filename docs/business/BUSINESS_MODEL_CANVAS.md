# UniFed Nigeria — Business Model Canvas

## Customer Segments
- **Primary (paying):** Universities (federal, state, private) — ADUN first.
- **Secondary:** University consortia, education ministries, accreditation bodies.
- **End users (free):** Students, lecturers, researchers, administrators.
- **Partners:** Employers, EdTech, research funders.

## Value Propositions
- A **Digital University OS** unifying records, identity, social, career, research, comms.
- **Federation-by-default**: each university owns its data; interoperable across nodes.
- **Portable digital student identity** (signed JWT QR) + verified academic records.
- NDPA-aligned, secure, observable, cloud-native.
- Avoids vendor lock-in; deployable on own infra or managed.

## Channels
- Founder-led university relationships (Christopher Chidera — founder/CEO).
- Pilot reference (ADUN) → peer-university referrals (federation effect).
- Grants/accelerators (visibility + non-dilutive capital).
- Technical communities (OSS, ActivityPub federation circles).

## Customer Relationships
- White-glove onboarding + ICT/SSO integration per university.
- Shared-success model (free pilot → paid conversion).
- Federation community (nodes help nodes).

## Revenue Streams
- Institutional annual license (Starter/Enterprise) — **primary**.
- Federated Network add-on.
- Premium modules (AI, career, research, support/SLA).
- Implementation/support services.
- Grants (non-dilutive).
- *(Not: student data sales.)*

## Key Resources
- Rails + Next.js codebase (16 bounded contexts, 151 RSpec, 12/12 frontend tests).
- Terraform/AWS foundation (VPC/EKS/RDS/Redis/S3/KMS).
- ADUN pilot relationship + reference.
- Founder domain expertise (Cloud/Cybersecurity, Nigerian HE).
- ActivityPub federation design (ADR-0003).

## Key Activities
- Finish M1 vertical slice + pilot deploy.
- Build federation (ActivityPub worker, F-04/05/06 closure).
- Secure NDPA compliance + IP assignment.
- Sign institutions; operate platform (SRE).
- Develop premium modules post-traction.

## Key Partnerships
- Admiralty University of Nigeria (reference node).
- AWS (cloud credits / Activate).
- EdTech/Employer networks (career).
- Research funders (impact grants).
- Legal/IP counsel (Nigeria + intl).

## Cost Structure
- **Fixed (dominant early):** engineering, security, compliance, SRE, G&A.
- **Variable:** per-university infra (~$4.8k/yr), per-student (~$1–$12/yr), onboarding (~$9.8k).
- See `FINANCIAL_MODEL.md`, `UNIT_ECONOMICS.md`.

---

## Role clarity (critical)
| Role | Who |
|---|---|
| PRIMARY CUSTOMER | The university (signs contract, pays) |
| SECONDARY CUSTOMER | Consortia / ministries |
| END USER | Student / lecturer / researcher (free) |
| ECONOMIC BUYER | University Pro-Chancellor / VC / Registrar |
| DECISION MAKER | VC + ICT Directorate + Procurement |

**Students are users, not customers.** This separation is the core of the model: free end-users
drive adoption and network effects; institutions pay for control, compliance, and federation value.
