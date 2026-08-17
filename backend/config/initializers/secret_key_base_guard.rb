# Fail-closed guard for Rails SECRET_KEY_BASE (STRIX F-12).
#
# Rails uses ENV["SECRET_KEY_BASE"] for session/cookie/CSRF signing. A blank or
# guessable default (e.g. "change-me-in-prod") lets an attacker forge sessions /
# CSRF tokens. Refuse to boot in production with an insecure value, matching the
# OIDC_JWKS_PRIVATE fail-closed pattern (F-01).
return unless Rails.env.production?

KNOWN_BAD_SECRET_KEY_BASE = %w[
  change-me-in-prod
  change-me
  dev-insecure-change-me
  ci-insecure-not-for-prod
].freeze

configured = ENV["SECRET_KEY_BASE"].to_s
if configured.empty? || KNOWN_BAD_SECRET_KEY_BASE.include?(configured)
  raise "SECRET_KEY_BASE is not configured with a strong secret " \
        "(refusing to boot production insecurely). Generate one with " \
        "`openssl rand -hex 64` and inject it via your deployment secrets."
end
