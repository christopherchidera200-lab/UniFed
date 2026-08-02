/**
 * Error taxonomy for the API layer.
 *
 * The UI branches on error *kind*, never on a parsed message string, so copy
 * changes in the backend cannot silently break error handling in the frontend.
 */

export type ApiErrorKind =
  | 'network'
  | 'timeout'
  | 'validation'
  | 'forbidden'
  | 'unauthorized'
  | 'not_found'
  | 'rate_limited'
  | 'server'
  | 'unknown';

export class ApiError extends Error {
  readonly kind: ApiErrorKind;
  readonly status: number | null;
  /** Machine-readable code from the backend envelope, when present. */
  readonly code: string | null;

  constructor(
    kind: ApiErrorKind,
    message: string,
    options: { status?: number | null; code?: string | null; cause?: unknown } = {},
  ) {
    super(message, { cause: options.cause });
    this.name = 'ApiError';
    this.kind = kind;
    this.status = options.status ?? null;
    this.code = options.code ?? null;
  }

  /** Maps an HTTP status onto the error taxonomy. */
  static kindForStatus(status: number): ApiErrorKind {
    if (status === 400 || status === 422) return 'validation';
    if (status === 401) return 'unauthorized';
    if (status === 403) return 'forbidden';
    if (status === 404) return 'not_found';
    if (status === 429) return 'rate_limited';
    if (status >= 500) return 'server';
    return 'unknown';
  }

  /**
   * Copy shown to the user. Deliberately free of internal detail: stack traces
   * and upstream messages are for logs, not for the screen.
   */
  get userMessage(): string {
    switch (this.kind) {
      case 'network':
        return 'Could not reach the CloudIntel API. Check your connection and try again.';
      case 'timeout':
        return 'The request took too long to complete. Try narrowing the investigation.';
      case 'validation':
        return this.message || 'That target does not look valid. Check the format and retry.';
      case 'forbidden':
        return this.message || 'That target is out of scope for CloudIntel.';
      case 'unauthorized':
        return 'Your session has expired. Sign in again to continue.';
      case 'not_found':
        return 'We could not find what you were looking for.';
      case 'rate_limited':
        return 'Rate limit reached. Wait a moment before running another investigation.';
      case 'server':
        return 'CloudIntel hit an unexpected error. The team has been notified.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
