# Legal & Ethics Policy

CloudIntel is an OSINT aggregator. Compliance is a product feature, not an afterthought.

## Hard rules (enforced in code)
1. **Public sources only.** No authentication bypass, no paywalled scraping, no credential reuse.
2. **Respect robots.txt and ToS.** Collectors that scrape must declare a source policy in
   `SourceDescriptor.legal_basis`. Sources without a clear basis are disabled by default.
3. **No active intrusion.** DNS/WHOIS/TLS handshakes to public endpoints only. No port scanning,
   no vulnerability probing, no brute force. Subdomain enumeration uses passive sources
   (Certificate Transparency logs) — never DNS brute force by default.
4. **No breach data resale.** Email exposure checks use HIBP's authorized API only, returning
   breach *names*, never plaintext credentials.
5. **Rate limiting + attribution.** Every collector identifies itself via User-Agent and honors
   upstream rate limits.

## Data protection
- Investigation targets are PII-adjacent. Records are encrypted at rest (DynamoDB KMS, S3 SSE-KMS).
- Retention: free tier 30 days, pro 1 year, enterprise configurable. TTL enforced in DynamoDB.
- Audit trail of every lookup (who, what, when) in CloudTrail + an app-level audit table.
- GDPR/NDPA: subject access + erasure endpoints are a launch requirement, not a v2 item.

## Abuse prevention
- Per-tenant quotas at API Gateway usage plans.
- Targets matching internal/reserved ranges (RFC1918, loopback, link-local) are rejected.
- Terms acceptance is recorded per user at signup.
