import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { TargetInput } from '../target-input';

describe('TargetInput', () => {
  it('disables submission until a target is entered', () => {
    render(<TargetInput onSubmit={vi.fn()} onCancel={vi.fn()} busy={false} />);
    expect(screen.getByRole('button', { name: /investigate/i })).toBeDisabled();
  });

  it('infers the target type as the user types', async () => {
    const user = userEvent.setup();
    render(<TargetInput onSubmit={vi.fn()} onCancel={vi.fn()} busy={false} />);

    await user.type(screen.getByRole('textbox'), 'analyst@example.com');

    // One field, no dropdown for the common path — but the guess is always visible.
    expect(screen.getByText(/detected as/i)).toHaveTextContent(/email/i);
  });

  it('submits the detected type', async () => {
    const onSubmit = vi.fn();
    const user = userEvent.setup();
    render(<TargetInput onSubmit={onSubmit} onCancel={vi.fn()} busy={false} />);

    await user.type(screen.getByRole('textbox'), 'example.com');
    await user.click(screen.getByRole('button', { name: /investigate/i }));

    expect(onSubmit).toHaveBeenCalledWith('example.com', 'domain');
  });

  it('lets the user override the inferred type', async () => {
    const onSubmit = vi.fn();
    const user = userEvent.setup();
    render(<TargetInput onSubmit={onSubmit} onCancel={vi.fn()} busy={false} />);

    await user.type(screen.getByRole('textbox'), 'example.com');
    // 'example.com' infers as a domain; force it to be treated as a username.
    await user.click(screen.getByRole('radio', { name: 'username' }));
    await user.click(screen.getByRole('button', { name: /investigate/i }));

    expect(onSubmit).toHaveBeenCalledWith('example.com', 'username');
  });

  it('trims surrounding whitespace before submitting', async () => {
    const onSubmit = vi.fn();
    const user = userEvent.setup();
    render(<TargetInput onSubmit={onSubmit} onCancel={vi.fn()} busy={false} />);

    await user.type(screen.getByRole('textbox'), '  example.com  ');
    await user.keyboard('{Enter}');

    expect(onSubmit).toHaveBeenCalledWith('example.com', 'domain');
  });

  it('submits on Enter without reaching for the mouse', async () => {
    const onSubmit = vi.fn();
    const user = userEvent.setup();
    render(<TargetInput onSubmit={onSubmit} onCancel={vi.fn()} busy={false} />);

    await user.type(screen.getByRole('textbox'), 'example.com{Enter}');

    expect(onSubmit).toHaveBeenCalledOnce();
  });

  it('offers Cancel instead of Investigate while a run is in flight', async () => {
    const onCancel = vi.fn();
    const user = userEvent.setup();
    render(<TargetInput onSubmit={vi.fn()} onCancel={onCancel} busy initialValue="example.com" />);

    expect(screen.queryByRole('button', { name: /investigate/i })).not.toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: /cancel/i }));

    expect(onCancel).toHaveBeenCalledOnce();
  });

  it('clears the field with the clear control', async () => {
    const user = userEvent.setup();
    render(<TargetInput onSubmit={vi.fn()} onCancel={vi.fn()} busy={false} initialValue="abc" />);

    await user.click(screen.getByRole('button', { name: /clear target/i }));

    expect(screen.getByRole('textbox')).toHaveValue('');
  });

  it('exposes the type override as a keyboard-navigable radiogroup', () => {
    render(<TargetInput onSubmit={vi.fn()} onCancel={vi.fn()} busy={false} />);
    expect(screen.getByRole('radiogroup', { name: /target type/i })).toBeInTheDocument();
  });
});
