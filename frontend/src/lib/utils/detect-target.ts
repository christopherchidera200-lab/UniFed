import { TARGET_TYPES, type TargetType } from '@/lib/api/types';

/**
 * Infers the target type from raw user input.
 *
 * UX rationale: forcing an analyst to classify their own input before searching
 * is a needless click and a needless decision. We infer, show what we inferred,
 * and let them override. Inference is intentionally conservative - when the
 * input is ambiguous we fall back to `domain`, the most common case.
 *
 * This is a UX affordance only. The backend re-validates every target in
 * `app/validation.py`; nothing here is a security control.
 */
export function detectTargetType(input: string): TargetType {
  const value = input.trim();
  if (!value) return 'domain';

  if (value.includes('@') && !value.startsWith('@')) return 'email';
  if (isIpv4(value) || isIpv6(value)) return 'ip';

  const host = stripUrl(value);
  if (host.includes('.')) return 'domain';

  return 'username';
}

/** Strips scheme, path, query and port so `https://a.com/x?y=1` reads as `a.com`. */
function stripUrl(value: string): string {
  return value
    .replace(/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//, '')
    .split('/')[0]!
    .split('?')[0]!
    .split(':')[0]!;
}

function isIpv4(value: string): boolean {
  const parts = value.split('.');
  if (parts.length !== 4) return false;
  return parts.every((part) => /^\d{1,3}$/.test(part) && Number(part) <= 255);
}

function isIpv6(value: string): boolean {
  // Loose shape check; the backend performs authoritative parsing.
  return value.includes(':') && /^[0-9a-fA-F:]+$/.test(value);
}

export function isTargetType(value: string): value is TargetType {
  return (TARGET_TYPES as readonly string[]).includes(value);
}

const TYPE_PLACEHOLDERS: Record<TargetType, string> = {
  domain: 'example.com',
  ip: '8.8.8.8',
  email: 'analyst@example.com',
  username: 'octocat',
  organization: 'google.com',
};

const TYPE_EXAMPLES: Record<TargetType, string> = {
  domain: 'a domain such as example.com',
  ip: 'a public IPv4 or IPv6 address',
  email: 'an email address',
  username: 'a username to check across public profiles',
  organization: 'an organization by its primary domain (e.g. google.com)',
};

const TARGET_LABELS: Record<TargetType, string> = {
  domain: 'Domain',
  ip: 'IP address',
  email: 'Email',
  username: 'Username',
  organization: 'Organization',
};

export function targetTypeLabel(type: TargetType): string {
  return TARGET_LABELS[type];
}

/** Placeholder seed appropriate to the active target type. */
export function targetPlaceholder(type: TargetType): string {
  return TYPE_PLACEHOLDERS[type];
}

/** Human description of what each type accepts, for the input hint. */
export function targetExample(type: TargetType): string {
  return TYPE_EXAMPLES[type];
}
