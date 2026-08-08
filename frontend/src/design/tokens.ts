/** UniFed Design System — refined per UI/UX Pro Max guidance.
 *  Style: Bento Box Grid (Apple-style modular cards, rounded-2xl, soft
 *  shadows, hover lift) over a Flat-design base. Palette: institutional navy
 *  + saffron warmth, WCAG-AA contrast. Mobile-first, light/dark, accessible.
 *  Typography: "Premium Sans" — DM Sans (display + body).
 */
export const tokens = {
  // Refined institutional palette (UI/UX Pro Max: Research Lab / University).
  color: {
    navy: {
      50: "#eef2fb", 100: "#dbe4f3", 200: "#b6c6e6", 300: "#84a3d6",
      400: "#4f6ec2", 500: "#1E3A5F", // institutional navy (primary)
      600: "#18304f", 700: "#13263f", 800: "#0e1c30", 900: "#0b1430", 950: "#070c1f"
    },
    // Brand blue secondary (links, interactive).
    brand: {
      50: "#eff6ff", 100: "#dbeafe", 200: "#bfdbfe", 300: "#93c5fd",
      400: "#60a5fa", 500: "#2563EB", 600: "#1d4ed8", 700: "#1e40af"
    },
    // Saffron / amber accent (warmth, CTAs, highlights).
    saffron: {
      50: "#fff7ed", 100: "#ffedd5", 200: "#fed7aa", 300: "#fdba74",
      400: "#fb923c", 500: "#f97316", 600: "#A16207", // refined amber accent
      700: "#c2410c", 800: "#9a3412", 900: "#7c2d12"
    },
    ink: { DEFAULT: "#0F172A", muted: "#475569", subtle: "#94a3b8" },
    surface: { light: "#FFFFFF", dark: "#0b1430" }
  },
  font: {
    display: "var(--font-display, 'DM Sans', system-ui, sans-serif)",
    body: "var(--font-body, 'DM Sans', system-ui, sans-serif)"
  },
  // Bento: generous radii + soft shadows (Apple-style).
  radius: { sm: "10px", md: "16px", lg: "22px", pill: "999px" },
  shadow: {
    soft: "0 1px 3px rgba(15,23,42,.06), 0 8px 24px rgba(15,23,42,.06)",
    lift: "0 4px 12px rgba(15,23,42,.08), 0 18px 40px rgba(15,23,42,.12)"
  },
  motion: { fast: "140ms", base: "220ms", ease: "cubic-bezier(.22,1,.36,1)" },
  // The 5 primary tabs (mandated). Lucide icon names replace emoji.
  nav: [
    { id: "home",     label: "Home",     icon: "home",       href: "/" },
    { id: "connect",  label: "Connect",  icon: "users",      href: "/connect" },
    { id: "create",   label: "Create",   icon: "plus",       href: "/create" },
    { id: "discover", label: "Discover", icon: "compass",    href: "/discover" },
    { id: "profile",  label: "Profile",  icon: "user",       href: "/profile" }
  ]
} as const;

export type UniFedTokens = typeof tokens;
