import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { RiskGauge } from '../risk-gauge';

describe('RiskGauge', () => {
  it('exposes the score as an accessible meter', () => {
    render(<RiskGauge score={42} band="elevated" />);

    const meter = screen.getByRole('meter');
    expect(meter).toHaveAttribute('aria-valuenow', '42');
    expect(meter).toHaveAttribute('aria-valuemin', '0');
    expect(meter).toHaveAttribute('aria-valuemax', '100');
  });

  it('names the band in the accessible label, not just by colour', () => {
    render(<RiskGauge score={80} band="high" />);

    // WCAG 1.4.1: colour alone must never be the only carrier of meaning.
    expect(screen.getByLabelText(/risk score 80 out of 100, high/i)).toBeInTheDocument();
    expect(screen.getByText('High')).toBeInTheDocument();
  });

  it('renders the numeric score as text', () => {
    render(<RiskGauge score={7} band="low" />);
    expect(screen.getByText('7')).toBeInTheDocument();
  });

  it('clamps an out-of-range score into 0-100', () => {
    render(<RiskGauge score={150} band="high" />);
    expect(screen.getByRole('meter')).toHaveAttribute('aria-valuenow', '100');
  });

  it('clamps a negative score to zero', () => {
    render(<RiskGauge score={-5} band="low" />);
    expect(screen.getByRole('meter')).toHaveAttribute('aria-valuenow', '0');
  });
});
