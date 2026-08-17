# UniFed Nigeria — Competitor Analysis (DRAFT)

> **DRAFT — strategy. Competitor names are categories/known players; no competitor internal data
> fabricated. Differentiation is argued from the repository's own architecture (ADRs, code).**

---

## 1. Competitive landscape (categories)

| Category | Examples (known) | Relationship to UniFed |
|---|---|---|
| LMS | Moodle, Canvas, Google Classroom | Substitute/partial; no social/federation/OS |
| SIS / Student Info | Ellucian, Unit4, local SIS | Partial overlap (records); not consumer UX |
| University portal | In-house portals, Microsoft 365/SharePoint | Substitute; not federated OS |
| Social network | Facebook/WhatsApp groups, Mastodon | Partial (social); not academic/sovereign |
| Career platform | LinkedIn, Jobberman, internal career offices | Future module competitor |
| Digital identity | National ID, institutional SSO | Complement/integration |
| Federated social | Mastodon, ActivityPub apps | Tech cousin; not HE-specific |

## 2. Direct vs indirect
- **Direct (closest):** none in Nigeria with "University OS + federation." Closest global = a
  university running Mastodon + Moodle + portal glue (fragile, non-integrated).
- **Indirect:** LMS vendors, portal builders, social groups students already use.

## 3. UniFed vs "a university portal"
A portal is **read-only-ish, siloed, single-institution, low UX**. UniFed is:
- **Integrated OS** (identity+records+social+career+library+events+research).
- **Federated** (cross-uni network, not a single silo).
- **Consumer-grade UX** (Next.js, social feed).
- **Sovereign** (each uni owns data; NDPA-aligned).

## 4. UniFed vs "a social network"
A social network is **generic, no academic records, no identity verification, no career, no
credentials**. UniFed binds social to **verified academic identity + records + credentials +
career**, inside a university-controlled instance. The combination is the product, not the feed.

## 5. The combined-advantage thesis
```
University OS  +  Federation (ActivityPub)  +  Digital Identity  +  Academic Services
+  Career  +  Social
```
Creates a **compounding moat**:
- **Network effects:** each new uni adds cross-instance content/people (federation).
- **Data sovereignty:** unis trust it (they own data) → easier adoption than a centralised platform.
- **Switching cost:** records+identity+social+career embedded → sticky.
- **Defensibility:** federation protocol + signed credentials + local academic model (ADUN ADR) are
  hard to replicate quickly.

## 6. Weaknesses to be honest about
- **No live pilot yet** (execution risk vs incumbents with installed base).
- **Small team** (bus-factor/execution capacity).
- **Federation complexity** under-estimated by many (moderation, abuse, interop).
- **Funding** to out-build incumbents' feature breadth.
- **Procurement** slow vs vendor relationships incumbents already have.

## 7. Barriers to entry / moat
- Protocol + federation governance.
- Signed-credential/transcript IP.
- Local academic data model (ADUN ADR-0005).
- Reference node + university relationships (ADUN first).
- OSS/community if pursued (ecosystem lock-in).

*See MARKET_ANALYSIS.md (opportunity), BUSINESS_MODEL_CANVAS.md (segments/advantage).*
