import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { EmptyState } from '../empty-state';
import { Button } from '../button';

describe('EmptyState', () => {
  it('always tells the user what to do next', () => {
    render(
      <EmptyState
        title="No investigations yet"
        description="Run your first investigation to see results here."
        action={<Button size="sm">New investigation</Button>}
      />,
    );

    expect(screen.getByText('No investigations yet')).toBeInTheDocument();
    expect(screen.getByText(/run your first investigation/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'New investigation' })).toBeInTheDocument();
  });

  it('hides the decorative icon from assistive technology', () => {
    const { container } = render(
      <EmptyState icon={<svg data-testid="icon" />} title="Empty" description="Nothing here." />,
    );

    expect(container.querySelector('[aria-hidden="true"]')).toBeTruthy();
  });
});
