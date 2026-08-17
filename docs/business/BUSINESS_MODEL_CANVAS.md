# UniFed Nigeria — Business Model Canvas (DRAFT)

> **DRAFT — strategy document. Assumptions labelled. No fabricated customers/users.**

---

## Customer Segments
- **PRIMARY CUSTOMER / ECONOMIC BUYER:** Universities (federal, state, private) in Nigeria, then
  West Africa. Budget-holder = ICT Directorate / VC office / Registry.
- **SECONDARY CUSTOMER:** University consortia, regulatory/ministry bodies, EdTech programmes
  (TETFund, NITDA), grantmakers.
- **END USER:** Students (undergrad/postgrad), academic staff, admin/registry, alumni.
- **DECISION MAKER:** University management (VC/Registrar/ICT Director) + procurement.

> Critical distinction: **students are users, not payers.** The university pays.

## Value Propositions
- One coherent **University OS**: identity + records + social + career + library + events + research.
- **Federation** via ActivityPub → cross-university network effects without a central data owner.
- **Data sovereignty**: each university owns its data (NDPA-aligned, privacy-by-design).
- **Digital student identity + verifiable credentials** (signed transcripts/IDs).
- Lower total cost vs bolting together portal + LMS + social + career tools.
- Local-first, Africa-context product (Nigerian academic model, matric schemes, SIWES).

## Channels
- Direct sales to university ICT/VC offices (founder-led early).
- Pilot → reference → expansion (ADUN first).
- Grantmaker + government programme pipelines.
- Developer/community channel (open-core, OSS-friendly positioning).
- (Future) partner/reseller for regional unis.

## Customer Relationships
- White-glove onboarding for pilot unis.
- Institutional account management (post-pilot).
- Community/developer engagement for federation adoption.
- Self-serve docs + status for mature unis.

## Revenue Streams
- Tiered institutional annual subscription (anchor).
- Premium modules (AI, analytics, career/employer, federation services).
- Implementation + support retainers.
- Grants (non-dilutive).
- (Scale) marketplace/creator transaction fees, white-label, employer recruitment.

## Key Resources
- Proprietary Rails codebase + IaC (Terraform/EKS) + federation IP.
- Engineering/Founder team (currently thin — see INVESTMENT_READINESS).
- ADUN pilot relationship + reference node.
- Security remediation work (STRIX) in progress.
- Legal/IP documentation set (draft).

## Key Activities
- Product engineering (complete M1, ship M2–M6 per roadmap).
- Federation hardening + security.
- University sales + onboarding.
- Compliance (NDPA, DPIA, legal agreements).
- Infrastructure delivery (cloud, cost-controlled).
- Partnerships (employers, government, grantmakers).

## Key Partnerships
- Admiralty University of Nigeria (pilot + reference).
- Cloud provider (AWS primary; portable).
- Grantmakers / development agencies.
- Employer networks (career module).
- Identity/credential verifiers.
- Local system integrators for on-prem enterprise unis.

## Cost Structure (see UNIT_ECONOMICS / CLOUD_COST_ANALYSIS)
- **Fixed:** personnel (engineering, DevOps, security, support), base cloud (per node), legal/compliance.
- **Variable:** per-university infra, per-student compute/storage/bandwidth, AI API consumption,
  support load, egress.
- **Major drivers:** headcount, Multi-AZ RDS, EKS, NAT/egress, AI tokens, support.

---

### Segment map (who/what/why)
| Role | Who | Pays? | Why UniFed |
|---|---|---|---|
| Primary customer | University (ICT/VC) | ✅ Yes | One OS, sovereign data, federation |
| Economic buyer | University budget | ✅ Yes | Budgeted annual contract |
| Decision maker | VC/Registrar/Procurement | Approves | Compliance + cost + network |
| End user | Student/staff | ❌ No (free) | Useful all-in-one product |
| Secondary | Govt/grantmaker | Funds | Digital-education/DPI mandate |
