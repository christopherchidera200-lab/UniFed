import { describe, expect, it } from 'vitest';
import { detectTargetType, isTargetType, targetTypeLabel } from '../detect-target';

describe('detectTargetType', () => {
  it.each([
    ['example.com', 'domain'],
    ['https://example.com/path?q=1', 'domain'],
    ['sub.example.co.uk', 'domain'],
    ['EXAMPLE.COM', 'domain'],
  ])('classifies %s as a domain', (input, expected) => {
    expect(detectTargetType(input)).toBe(expected);
  });

  it.each([
    ['8.8.8.8', 'ip'],
    ['1.1.1.1', 'ip'],
    ['2001:4860:4860::8888', 'ip'],
  ])('classifies %s as an IP', (input, expected) => {
    expect(detectTargetType(input)).toBe(expected);
  });

  it('classifies an address with an @ as an email', () => {
    expect(detectTargetType('analyst@example.com')).toBe('email');
  });

  it('treats a leading @ as a username handle, not an email', () => {
    expect(detectTargetType('@octocat')).toBe('username');
  });

  it('classifies a dotless token as a username', () => {
    expect(detectTargetType('octocat')).toBe('username');
  });

  it('rejects an out-of-range octet as an IP and falls back to domain shape', () => {
    // 999 is not a valid octet, so this is not an IP. It still contains dots,
    // so the conservative fallback is `domain` - the backend rejects it properly.
    expect(detectTargetType('999.999.999.999')).toBe('domain');
  });

  it('defaults empty and whitespace input to domain', () => {
    expect(detectTargetType('')).toBe('domain');
    expect(detectTargetType('   ')).toBe('domain');
  });
});

describe('isTargetType', () => {
  it('accepts known target types and rejects others', () => {
    expect(isTargetType('domain')).toBe(true);
    expect(isTargetType('organization')).toBe(false);
  });
});

describe('targetTypeLabel', () => {
  it('returns human-readable labels', () => {
    expect(targetTypeLabel('ip')).toBe('IP address');
  });
});
