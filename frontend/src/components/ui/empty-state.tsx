import type { ReactNode } from 'react';
import { cn } from '@/lib/utils/cn';

export interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description: string;
  action?: ReactNode;
  className?: string;
}

/**
 * Empty and zero-result states.
 *
 * Product rule: an empty state must always tell the user what to do next.
 * A blank panel that only says "No data" is treated as a defect in review.
 */
export function EmptyState({ icon, title, description, action, className }: EmptyStateProps) {
  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center gap-3 px-6 py-14 text-center',
        className,
      )}
    >
      {icon && (
        <div
          aria-hidden="true"
          className="flex h-10 w-10 items-center justify-center rounded-lg bg-muted text-subtle"
        >
          {icon}
        </div>
      )}
      <div className="space-y-1">
        <p className="text-sm font-medium text-foreground">{title}</p>
        <p className="mx-auto max-w-sm text-xs leading-relaxed text-subtle">{description}</p>
      </div>
      {action}
    </div>
  );
}
