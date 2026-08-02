import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { Badge, riskTone, severityTone, statusTone } from '../badge';

describe('Badge', () => {
  it('renders a text label, so colour is never the only signal (WCAG 1.4.1)', () => {
    render(<Badge tone="high">High</Badge>);
    expect(screen.getByText('High')).toBeInTheDocument();
  });
});

describe('tone mappings', () => {
  it('maps severities to their palette tone', () => {
    expect(severityTone('high')).toBe('high');
    expect(severityTone('info')).toBe('info');
  });

  it('maps a low risk band to the success tone, not a warning tone', () => {
    expect(riskTone('low')).toBe('success');
    expect(riskTone('high')).toBe('high');
  });

  it('maps collector statuses so failures read as problems', () => {
    expect(statusTone('ok')).toBe('success');
    expect(statusTone('error')).toBe('high');
    expect(statusTone('timeout')).toBe('medium');
    expect(statusTone('skipped')).toBe('neutral');
  });
});
