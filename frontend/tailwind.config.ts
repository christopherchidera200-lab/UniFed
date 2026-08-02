import type { Config } from 'tailwindcss';

/**
 * Tailwind consumes design tokens indirectly, via the CSS custom properties
 * declared in src/app/globals.css. Components therefore never hardcode a hex
 * value, and theming (light/dark) is a single attribute flip on <html>.
 */
const config: Config = {
  darkMode: ['class', '[data-theme="dark"]'],
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        canvas: 'hsl(var(--canvas) / <alpha-value>)',
        surface: 'hsl(var(--surface) / <alpha-value>)',
        elevated: 'hsl(var(--elevated) / <alpha-value>)',
        border: 'hsl(var(--border) / <alpha-value>)',
        'border-strong': 'hsl(var(--border-strong) / <alpha-value>)',
        muted: 'hsl(var(--muted) / <alpha-value>)',
        foreground: 'hsl(var(--foreground) / <alpha-value>)',
        subtle: 'hsl(var(--subtle) / <alpha-value>)',
        accent: {
          DEFAULT: 'hsl(var(--accent) / <alpha-value>)',
          foreground: 'hsl(var(--accent-foreground) / <alpha-value>)',
          subtle: 'hsl(var(--accent-subtle) / <alpha-value>)',
        },
        // Severity + risk-band palette. Shared by badges, score rings and charts
        // so a "high" finding is the same colour everywhere in the product.
        severity: {
          info: 'hsl(var(--severity-info) / <alpha-value>)',
          low: 'hsl(var(--severity-low) / <alpha-value>)',
          medium: 'hsl(var(--severity-medium) / <alpha-value>)',
          high: 'hsl(var(--severity-high) / <alpha-value>)',
        },
        success: 'hsl(var(--success) / <alpha-value>)',
        danger: 'hsl(var(--danger) / <alpha-value>)',
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        DEFAULT: 'var(--radius)',
        lg: 'var(--radius-lg)',
        xl: 'var(--radius-xl)',
      },
      fontFamily: {
        sans: ['var(--font-sans)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-mono)', 'ui-monospace', 'monospace'],
      },
      fontSize: {
        '2xs': ['0.6875rem', { lineHeight: '1rem', letterSpacing: '0.02em' }],
      },
      boxShadow: {
        xs: 'var(--shadow-xs)',
        sm: 'var(--shadow-sm)',
        md: 'var(--shadow-md)',
        lg: 'var(--shadow-lg)',
      },
      keyframes: {
        'fade-in': { from: { opacity: '0' }, to: { opacity: '1' } },
        'slide-up': {
          from: { opacity: '0', transform: 'translateY(4px)' },
          to: { opacity: '1', transform: 'translateY(0)' },
        },
        shimmer: {
          '100%': { transform: 'translateX(100%)' },
        },
      },
      animation: {
        'fade-in': 'fade-in 150ms ease-out',
        'slide-up': 'slide-up 200ms cubic-bezier(0.16, 1, 0.3, 1)',
        shimmer: 'shimmer 1.6s infinite',
      },
    },
  },
  plugins: [],
};

export default config;
