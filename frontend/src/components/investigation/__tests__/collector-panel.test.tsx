import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it } from 'vitest';
import { CollectorPanel, CollectorPending } from '../collector-panel';
import type { CollectorResult, Finding } from '@/lib/api/types';

function finding(overrides: Partial<Finding> = {}): Finding {
  return {
    collector: 'dns',
    title: 'DNS records',
    severity: 'info',
    data: { records: { A: ['1.2.3.4'] } },
    source: 'DNS (1.1.1.1)',
    legal_basis: 'DNS is a public directory designed for open query.',
    ...overrides,
  };
}

function result(overrides: Partial<CollectorResult> = {}): CollectorResult {
  return {
    collector: 'dns',
    status: 'ok',
    duration_ms: 1200,
    cached: false,
    error: null,
    findings: [finding()],
    ...overrides,
  };
}

describe('CollectorPanel', () => {
  it('renders the collector name, status and duration', () => {
    render(<CollectorPanel result={result()} />);

    expect(screen.getByRole('heading', { name: /dns/i })).toBeInTheDocument();
    expect(screen.getByText('ok')).toBeInTheDocument();
    expect(screen.getByText('1.2s')).toBeInTheDocument();
  });

  it('collapses finding detail by default', () => {
    render(<CollectorPanel result={result()} />);

    expect(screen.getByRole('button', { expanded: false })).toBeInTheDocument();
    expect(screen.queryByText(/legal basis/i)).not.toBeInTheDocument();
  });

  it('reveals the payload and legal basis when a finding is expanded', async () => {
    const user = userEvent.setup();
    render(<CollectorPanel result={result()} />);

    await user.click(screen.getByRole('button', { name: /DNS records/i }));

    expect(screen.getByRole('button', { expanded: true })).toBeInTheDocument();
    expect(screen.getByText(/legal basis/i)).toBeInTheDocument();
    // The legal justification is the product's core claim — it must be reachable.
    expect(screen.getByText(/public directory designed for open query/i)).toBeInTheDocument();
  });

  it('explains an empty result instead of showing a bare "no data"', () => {
    render(<CollectorPanel result={result({ status: 'empty', findings: [] })} />);

    expect(screen.getByText(/normal result, not a failure/i)).toBeInTheDocument();
  });

  it('reassures the user that a timeout did not affect other sources', () => {
    render(
      <CollectorPanel
        result={result({ status: 'timeout', findings: [], error: 'Source did not respond' })}
      />,
    );

    expect(screen.getByText(/other sources were unaffected/i)).toBeInTheDocument();
  });

  it('surfaces the underlying error text for a failed source', () => {
    render(
      <CollectorPanel
        result={result({ status: 'error', findings: [], error: '503 Service Unavailable' })}
      />,
    );

    expect(screen.getByText('503 Service Unavailable')).toBeInTheDocument();
  });

  it('marks a cached result', () => {
    render(<CollectorPanel result={result({ cached: true })} />);
    expect(screen.getByText('cached')).toBeInTheDocument();
  });

  it('renders every finding a collector returned', () => {
    render(
      <CollectorPanel
        result={result({
          findings: [
            finding({ title: 'First' }),
            finding({ title: 'Second', severity: 'medium' }),
          ],
        })}
      />,
    );

    expect(screen.getByText('First')).toBeInTheDocument();
    expect(screen.getByText('Second')).toBeInTheDocument();
    expect(screen.getByText('medium')).toBeInTheDocument();
  });
});

describe('CollectorPending', () => {
  it('labels the pending source for assistive technology', () => {
    render(<CollectorPending name="whois" />);

    // Screen-reader users must know a source is still working, not missing.
    expect(screen.getByLabelText(/whois — in progress/i)).toBeInTheDocument();
    expect(screen.getByText('running')).toBeInTheDocument();
  });
});
