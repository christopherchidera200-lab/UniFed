import type { Metadata, Viewport } from 'next';
import { ThemeProvider, themeInitScript } from '@/components/theme/theme-provider';
import './globals.css';

export const metadata: Metadata = {
  title: {
    default: 'CloudIntel — Legal OSINT aggregation',
    template: '%s · CloudIntel',
  },
  description:
    'Aggregate legal open-source intelligence on domains, IP addresses, emails and usernames ' +
    'into one secure dashboard. Public sources and authorized APIs only.',
  applicationName: 'CloudIntel',
  robots: { index: false, follow: false },
};

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#0d1117' },
  ],
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        {/* Resolves the theme before first paint. See themeInitScript. */}
        <script dangerouslySetInnerHTML={{ __html: themeInitScript }} />
      </head>
      <body className="min-h-dvh font-sans">
        <a href="#main" className="skip-link">
          Skip to main content
        </a>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
