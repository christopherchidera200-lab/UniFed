import { cn } from "@/lib/cn";
import { ReactNode } from "react";

/** Bento-style card: rounded-2xl, soft shadow, optional hover lift. */
export function Card({
  children,
  className,
  hover = false
}: {
  children: ReactNode;
  className?: string;
  hover?: boolean;
}) {
  return (
    <div className={cn("card p-4", hover && "card-hover", className)}>{children}</div>
  );
}

/** Section heading with optional eyebrow + action slot. */
export function SectionHeader({
  title,
  eyebrow,
  action
}: {
  title: string;
  eyebrow?: string;
  action?: ReactNode;
}) {
  return (
    <header className="flex items-end justify-between gap-3">
      <div>
        {eyebrow && (
          <p className="text-xs font-medium uppercase tracking-wide text-ink-subtle">
            {eyebrow}
          </p>
        )}
        <h2 className="font-display text-xl font-bold text-ink">{title}</h2>
      </div>
      {action}
    </header>
  );
}

/** Circular icon badge with tinted background. */
export function IconBadge({
  children,
  className
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "grid h-10 w-10 shrink-0 place-items-center rounded-xl text-lg",
        className
      )}
    >
      {children}
    </span>
  );
}
