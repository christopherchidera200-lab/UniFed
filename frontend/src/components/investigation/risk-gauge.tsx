import { cn } from '@/lib/utils/cn';
import type { RiskBand } from '@/lib/api/types';

const BAND_LABEL: Record<RiskBand, string> = {
  low: 'Low',
  moderate: 'Moderate',
  elevated: 'Elevated',
  high: 'High',
};

// Deliberately not a red/green pair alone: the band NAME is always rendered, so
// colour is reinforcement rather than the sole carrier of meaning (WCAG 1.4.1).
const BAND_COLOR: Record<RiskBand, string> = {
  low: 'text-success',
  moderate: 'text-severity-low',
  elevated: 'text-severity-medium',
  high: 'text-severity-high',
};

export interface RiskGaugeProps {
  score: number;
  band: RiskBand;
  className?: string;
}

/**
 * Circular risk indicator.
 *
 * Rendered as an SVG ring rather than a bar so it reads as a single headline
 * number — the one thing an analyst looks at first.
 *
 * Accessibility: exposed as a `meter` with explicit aria values, and the score
 * and band are both present as real text for screen readers.
 */
export function RiskGauge({ score, band, className }: RiskGaugeProps) {
  const radius = 34;
  const circumference = 2 * Math.PI * radius;
  const clamped = Math.min(100, Math.max(0, score));
  const dash = (clamped / 100) * circumference;

  return (
    <div className={cn('flex items-center gap-4', className)}>
      <div
        className="relative h-20 w-20 shrink-0"
        role="meter"
        aria-valuenow={clamped}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label={`Risk score ${clamped} out of 100, ${BAND_LABEL[band]}`}
      >
        <svg viewBox="0 0 80 80" className="h-full w-full -rotate-90" aria-hidden="true">
          <circle
            cx="40"
            cy="40"
            r={radius}
            fill="none"
            strokeWidth="6"
            className="stroke-muted"
          />
          <circle
            cx="40"
            cy="40"
            r={radius}
            fill="none"
            strokeWidth="6"
            strokeLinecap="round"
            strokeDasharray={`${dash} ${circumference}`}
            className={cn('transition-[stroke-dasharray] duration-700 ease-out', BAND_COLOR[band])}
            stroke="currentColor"
          />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          <span className={cn('text-xl font-semibold tabular-nums', BAND_COLOR[band])}>
            {clamped}
          </span>
        </div>
      </div>

      <div className="min-w-0">
        <p className="text-xs uppercase tracking-wide text-subtle">Risk score</p>
        <p className={cn('text-sm font-semibold', BAND_COLOR[band])}>{BAND_LABEL[band]}</p>
        <p className="mt-0.5 text-xs text-subtle">out of 100</p>
      </div>
    </div>
  );
}
