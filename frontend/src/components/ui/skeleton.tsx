import { cn } from '@/lib/utils/cn';

/**
 * Shimmer placeholder used while data loads.
 *
 * Skeletons (rather than spinners) are used wherever the final layout is known,
 * because they preserve perceived performance and prevent layout shift (CLS).
 *
 * Accessibility: marked aria-hidden. The surrounding region owns the live-region
 * announcement, so screen readers hear "Loading investigations" once instead of
 * a burst of meaningless placeholder nodes.
 */
export function Skeleton({ className }: { className?: string }) {
  return (
    <div
      aria-hidden="true"
      className={cn('relative overflow-hidden rounded bg-muted', className)}
    >
      <div className="absolute inset-0 -translate-x-full animate-shimmer bg-gradient-to-r from-transparent via-foreground/[0.06] to-transparent" />
    </div>
  );
}
