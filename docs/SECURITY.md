# Security Policy — UniFed Nigeria

UniFed handles student PII and academic records. Security-by-design and
privacy-by-design are non-negotiable (ADR-0004, ADR-0005).

## Principles
- **Least privilege:** every endpoint is role + owning-university scoped.
- **Privacy-by-design:** raw digital-ID tokens are never persisted in cleartext
  (only SHA-256 hashes); verification is fully audited.
- **Encryption:** data at rest (KMS) and in transit (TLS 1.2+, IRSA) everywhere.
- **Secrets:** AWS Secrets Manager only; never in env files or images.
- **Federation trust:** ActivityPub activities are signature-verified (HTTP
  Signatures / LD-Signatures) before acceptance.

## Reporting a vulnerability
Email **security@unifed.ng**. Do **not** open public issues for security flaws.
We acknowledge within 48h and aim for a fix within 14 days for criticals.

## Supported versions
The `master` branch of the current milestone (M1) is supported.
