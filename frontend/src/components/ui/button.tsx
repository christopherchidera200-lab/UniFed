import { forwardRef, type ButtonHTMLAttributes } from 'react';
import { cn } from '@/lib/utils/cn';

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';
type Size = 'sm' | 'md' | 'lg';

const VARIANTS: Record<Variant, string> = {
  primary:
    'bg-accent text-accent-foreground shadow-xs hover:brightness-110 active:brightness-95 disabled:hover:brightness-100',
  secondary:
    'bg-surface text-foreground border border-border shadow-xs hover:bg-muted active:bg-muted',
  ghost: 'text-subtle hover:bg-muted hover:text-foreground',
  danger: 'bg-danger text-white shadow-xs hover:brightness-110 active:brightness-95',
};

const SIZES: Record<Size, string> = {
  sm: 'h-8 px-3 text-xs gap-1.5 rounded',
  md: 'h-9 px-4 text-sm gap-2 rounded',
  lg: 'h-11 px-5 text-sm gap-2 rounded-lg',
};

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  /** Renders a spinner and blocks interaction without collapsing layout. */
  loading?: boolean;
}

/**
 * The single button primitive for the product.
 *
 * Accessibility: when `loading`, the button is disabled and marked aria-busy so
 * screen readers announce the pending state rather than a silently dead control.
 */
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { className, variant = 'primary', size = 'md', loading = false, disabled, children, ...props },
  ref,
) {
  return (
    <button
      ref={ref}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      className={cn(
        'inline-flex select-none items-center justify-center whitespace-nowrap font-medium',
        'transition-[background-color,filter,opacity] duration-150',
        'disabled:cursor-not-allowed disabled:opacity-50',
        VARIANTS[variant],
        SIZES[size],
        className,
      )}
      {...props}
    >
      {loading && <Spinner />}
      {children}
    </button>
  );
});

function Spinner() {
  return (
    <svg className="h-3.5 w-3.5 animate-spin" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
      <path
        className="opacity-90"
        fill="currentColor"
        d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"
      />
    </svg>
  );
}
