'use client';

import { useEffect, useId, useState, type FormEvent } from 'react';
import { Search, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { TARGET_TYPES, type TargetType } from '@/lib/api/types';
import { detectTargetType, targetTypeLabel, targetPlaceholder, targetExample } from '@/lib/utils/detect-target';
import { cn } from '@/lib/utils/cn';

export interface TargetInputProps {
  onSubmit: (target: string, targetType: TargetType) => void;
  onCancel: () => void;
  busy: boolean;
  /** Seeds the field, e.g. when arriving from a shared link. */
  initialValue?: string;
}

/**
 * The primary entry point of the product.
 *
 * UX decisions:
 *   - The target type is INFERRED as the user types, so the common path is one
 *     field and one Enter press. The inferred type is shown and overridable — we
 *     guess, but we never hide the guess or prevent correction.
 *   - The override control is a real radiogroup, not a custom dropdown, so it is
 *     keyboard-navigable with arrow keys for free.
 *   - While a run is in flight the submit button becomes Cancel, because the most
 *     likely next intent during a slow investigation is to stop it.
 */
export function TargetInput({ onSubmit, onCancel, busy, initialValue = '' }: TargetInputProps) {
  const [value, setValue] = useState(initialValue);
  const [override, setOverride] = useState<TargetType | null>(null);
  const inputId = useId();
  const hintId = useId();

  const detected = detectTargetType(value);
  const effectiveType = override ?? detected;

  // Clear a manual override when the input changes shape, so typing an email
  // after investigating a domain does not silently keep the wrong type.
  useEffect(() => {
    setOverride(null);
  }, [detected]);

  function handleSubmit(event: FormEvent) {
    event.preventDefault();
    const trimmed = value.trim();
    if (!trimmed || busy) return;
    onSubmit(trimmed, effectiveType);
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-3">
      <label htmlFor={inputId} className="sr-only">
        Investigation target
      </label>

      <div className="flex gap-2">
        <div className="relative flex-1">
          <Search
            className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-subtle"
            aria-hidden="true"
          />
          <input
            id={inputId}
            type="text"
            value={value}
            onChange={(event) => setValue(event.target.value)}
            placeholder={targetPlaceholder(effectiveType)}
            aria-describedby={hintId}
            autoComplete="off"
            spellCheck={false}
            // Mobile Safari applies autocapitalise and autocorrect to text inputs
            // by default, which mangles targets like an email or a lowercase
            // username as they are typed. Disabling both is correct for an
            // identifier field regardless of platform.
            autoCapitalize="none"
            autoCorrect="off"
            inputMode="url"
            className={cn(
              'h-11 w-full rounded-lg border border-border-strong bg-surface pl-9 pr-9',
              'text-sm text-foreground placeholder:text-subtle',
              'transition-colors hover:border-accent/50 focus:border-accent',
            )}
          />
          {value && (
            <button
              type="button"
              onClick={() => setValue('')}
              aria-label="Clear target"
              className="absolute right-2 top-1/2 -translate-y-1/2 rounded p-1 text-subtle hover:bg-muted hover:text-foreground"
            >
              <X className="h-3.5 w-3.5" aria-hidden="true" />
            </button>
          )}
        </div>

        {busy ? (
          <Button type="button" variant="secondary" size="lg" onClick={onCancel}>
            Cancel
          </Button>
        ) : (
          <Button type="submit" size="lg" disabled={!value.trim()}>
            Investigate
          </Button>
        )}
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <span id={hintId} className="text-xs text-subtle">
          Detected as <span className="font-medium text-foreground">{targetTypeLabel(detected)}</span>.
          Override:
        </span>
        <div role="radiogroup" aria-label="Target type" className="flex flex-wrap gap-1">
          {TARGET_TYPES.map((type) => {
            const selected = effectiveType === type;
            return (
              <button
                key={type}
                type="button"
                role="radio"
                aria-checked={selected}
                onClick={() => setOverride(type)}
                className={cn(
                  'rounded-full px-2.5 py-1 text-2xs font-medium uppercase transition-colors',
                  'ring-1 ring-inset',
                  selected
                    ? 'bg-accent text-accent-foreground ring-accent'
                    : 'bg-surface text-subtle ring-border hover:bg-muted hover:text-foreground',
                )}
              >
                {type}
              </button>
            );
          })}
        </div>
      </div>
      <p className="text-xs text-subtle">
        Investigating {targetExample(effectiveType)}. Only public, lawfully accessible sources are queried.
      </p>
    </form>
  );
}
