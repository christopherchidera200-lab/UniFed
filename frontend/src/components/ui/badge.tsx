import type { HTMLAttributes } from 'react';
import { cn } from '@/lib/utils/cn';
import type { CollectorStatus, RiskBand, Severity } from '@/lib/api/types';

type Tone = 'neutral' | 'info' | 'low' | 'medium' | 'high' | 'success';

const TONES: Record<Tone, string> = {
  neutral: 'bg-muted text-subtle ring-border',
  info: 'bg-muted text-subtle ring-border',
  low: 'bg-severity-low/10 text-severity-low ring-severity-low/25',
  medium: 'bg-severity-medium/10 text-severity-medium ring-severity-medium/25',
  high: 'bg-severity-high/10 text-severity-high ring-severity-high/25',
  success: 'bg-success/10 text-success ring-success/25',
};

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  tone?: Tone;
}

/**
 * Compact status pill.
 *
 * Accessibility: tone is never the sole carrier of meaning - the badge always
 * renders a text label too, satisfying WCAG 1.4.1 (Use of Colour).
 */
export function Badge({ className, tone = 'neutral', ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-2xs font-medium uppercase',
        'ring-1 ring-inset',
        TONES[tone],
        className,
      )}
      {...props}
    />
  );
}

const SEVERITY_TONE: Record<Severity, Tone> = {
  info: 'info',
  low: 'low',
  medium: 'medium',
  high: 'high',
};

export function severityTone(severity: Severity): Tone {
  return SEVERITY_TONE[severity];
}

const RISK_TONE: Record<RiskBand, Tone> = {
  low: 'success',
  moderate: 'low',
  elevated: 'medium',
  high: 'high',
};

export function riskTone(band: RiskBand): Tone {
  return RISK_TONE[band];
}

const STATUS_TONE: Record<CollectorStatus, Tone> = {
  ok: 'success',
  empty: 'neutral',
  timeout: 'medium',
  error: 'high',
  skipped: 'neutral',
};

export function statusTone(status: CollectorStatus): Tone {
  return STATUS_TONE[status];
}
