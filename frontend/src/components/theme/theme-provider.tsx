'use client';

import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react';

export type Theme = 'light' | 'dark';

const STORAGE_KEY = 'cloudintel-theme';

interface ThemeContextValue {
  theme: Theme;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

/**
 * Theme state, persisted to localStorage and mirrored onto <html data-theme>.
 *
 * The initial value is read from the DOM attribute rather than from storage,
 * because the inline script in layout.tsx has already resolved the correct theme
 * before first paint. Reading the DOM keeps React in sync with what the user can
 * already see, avoiding a hydration mismatch and a theme flash.
 */
export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('light');

  useEffect(() => {
    const current = document.documentElement.dataset.theme;
    setTheme(current === 'dark' ? 'dark' : 'light');
  }, []);

  const toggleTheme = useCallback(() => {
    setTheme((previous) => {
      const next: Theme = previous === 'dark' ? 'light' : 'dark';
      document.documentElement.dataset.theme = next;
      try {
        window.localStorage.setItem(STORAGE_KEY, next);
      } catch {
        // Storage can be unavailable (private mode, blocked cookies).
        // Theme still applies for this session; persistence is best-effort.
      }
      return next;
    });
  }, []);

  return <ThemeContext.Provider value={{ theme, toggleTheme }}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const context = useContext(ThemeContext);
  if (!context) throw new Error('useTheme must be used within a ThemeProvider');
  return context;
}

/**
 * Blocking script injected into <head>. Runs before paint so the correct theme
 * is applied on the very first frame - this is what prevents the white flash
 * that gives away an amateur dark-mode implementation.
 */
export const themeInitScript = `
(function () {
  try {
    var stored = localStorage.getItem('${STORAGE_KEY}');
    var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    document.documentElement.dataset.theme =
      stored === 'light' || stored === 'dark' ? stored : (prefersDark ? 'dark' : 'light');
  } catch (e) {
    document.documentElement.dataset.theme = 'light';
  }
})();
`;
