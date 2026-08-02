'use client';

import { Moon, Sun } from 'lucide-react';
import { useTheme } from './theme-provider';
import { Button } from '@/components/ui/button';

/**
 * Light/dark switch.
 *
 * Accessibility: the icon is decorative, so the control carries an explicit
 * aria-label describing the *action*, and aria-pressed exposes current state.
 */
export function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();
  const isDark = theme === 'dark';

  return (
    <Button
      variant="ghost"
      size="sm"
      onClick={toggleTheme}
      aria-label={isDark ? 'Switch to light theme' : 'Switch to dark theme'}
      aria-pressed={isDark}
      className="h-8 w-8 p-0"
    >
      {isDark ? (
        <Sun className="h-4 w-4" aria-hidden="true" />
      ) : (
        <Moon className="h-4 w-4" aria-hidden="true" />
      )}
    </Button>
  );
}
