import { describe, expect, it } from 'vitest';
import { ApiError } from '../errors';

describe('ApiError.kindForStatus', () => {
  it.each([
    [400, 'validation'],
    [422, 'validation'],
    [401, 'unauthorized'],
    [403, 'forbidden'],
    [404, 'not_found'],
    [429, 'rate_limited'],
    [500, 'server'],
    [503, 'server'],
    [418, 'unknown'],
  ])('maps HTTP %i to %s', (status, expected) => {
    expect(ApiError.kindForStatus(status)).toBe(expected);
  });
});

describe('ApiError.userMessage', () => {
  it('never leaks internal detail for server errors', () => {
    const error = new ApiError('server', 'psycopg2.OperationalError at 10.0.3.4:5432');
    expect(error.userMessage).not.toContain('psycopg2');
    expect(error.userMessage).not.toContain('10.0.3.4');
  });

  it('surfaces the backend message for validation errors, which are user-actionable', () => {
    const error = new ApiError('validation', "'!!' is not a valid domain name");
    expect(error.userMessage).toContain('not a valid domain name');
  });

  it('falls back to generic copy when a validation error carries no message', () => {
    expect(new ApiError('validation', '').userMessage).toContain('does not look valid');
  });

  it('preserves status and code metadata', () => {
    const error = new ApiError('forbidden', 'Out of scope', { status: 403, code: 'forbidden_target' });
    expect(error.status).toBe(403);
    expect(error.code).toBe('forbidden_target');
  });
});
