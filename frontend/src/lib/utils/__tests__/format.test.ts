import { describe, expect, it } from 'vitest';
import { formatAbsoluteTime, formatDuration, formatRelativeTime, pluralize } from '../format';

describe('formatDuration', () => {
  it('renders sub-second values in milliseconds', () => {
    expect(formatDuration(842)).toBe('842ms');
  });

  it('renders values of a second or more in seconds', () => {
    expect(formatDuration(1000)).toBe('1.0s');
    expect(formatDuration(15_432)).toBe('15.4s');
  });

  it('returns a dash for invalid input rather than NaN', () => {
    expect(formatDuration(Number.NaN)).toBe('—');
    expect(formatDuration(-5)).toBe('—');
  });
});

describe('formatRelativeTime', () => {
  const now = new Date('2026-08-02T12:00:00Z');

  it.each([
    ['2026-08-02T11:59:30Z', 'just now'],
    ['2026-08-02T11:45:00Z', '15m ago'],
    ['2026-08-02T09:00:00Z', '3h ago'],
    ['2026-07-30T12:00:00Z', '3d ago'],
  ])('formats %s as %s', (iso, expected) => {
    expect(formatRelativeTime(iso, now)).toBe(expected);
  });

  it('clamps future timestamps to "just now" instead of showing negatives', () => {
    expect(formatRelativeTime('2026-08-02T12:05:00Z', now)).toBe('just now');
  });

  it('returns a dash for an unparseable timestamp', () => {
    expect(formatRelativeTime('not-a-date', now)).toBe('—');
  });
});

describe('formatAbsoluteTime', () => {
  it('returns a dash for an unparseable timestamp', () => {
    expect(formatAbsoluteTime('nope')).toBe('—');
  });
});

describe('pluralize', () => {
  it('uses the singular form for exactly one', () => {
    expect(pluralize(1, 'finding')).toBe('1 finding');
  });

  it('uses the plural form otherwise', () => {
    expect(pluralize(0, 'finding')).toBe('0 findings');
    expect(pluralize(3, 'finding')).toBe('3 findings');
  });
});
