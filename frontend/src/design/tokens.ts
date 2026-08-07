/** UniFed Design System — design tokens.
 *  A distinctive, premium identity. Mobile-first, dark/light, accessible.
 *  NOTE: ADUN official brand colours/logos are NOT yet provided (per brief —
 *  do not invent). These are the UniFed product tokens; institutional theming
 *  slots in via CSS variables consumed from the API at runtime.
 */
export const tokens = {
  // Core palette — deep "academic navy" + warm "saffron" accent (placeholder
  // until ADUN brand is supplied; chosen for contrast + African warmth).
  color: {
    navy: {
      50: "#eef2fb", 100: "#d6def4", 200: "#aebfe9", 300: "#7d97d8",
      400: "#4f6ec2", 500: "#2f4ea3", 600: "#223a80", 700: "#1a2c61",
      800: "#121f44", 900: "#0b1430", 950: "#070c1f"
    },
    saffron: {
      50: "#fff7ed", 100: "#ffedd5", 200: "#fed7aa", 300: "#fdba74",
      400: "#fb923c", 500: "#f97316", 600: "#ea580c", 700: "#c2410c",
      800: "#9a3412", 900: "#7c2d12"
    },
    ink: { DEFAULT: "#0b1430", muted: "#5b6480", subtle: "#9aa3bd" },
    surface: { light: "#ffffff", dark: "#0b1430" }
  },
  // Typography — a refined sans stack; swap to a licensed display face later.
  font: {
    display: "var(--font-display, 'Space Grotesk', system-ui, sans-serif)",
    body: "var(--font-body, 'Inter', system-ui, sans-serif)"
  },
  radius: { sm: "8px", md: "14px", lg: "22px", pill: "999px" },
  // Motion — calm, confident.
  motion: { fast: "120ms", base: "220ms", slow: "360ms", ease: "cubic-bezier(.22,1,.36,1)" },
  shadow: {
    soft: "0 2px 12px rgba(11,20,48,.06)",
    lift: "0 12px 40px rgba(11,20,48,.12)"
  },
  // Navigation — the 5 primary tabs mandated by the brief.
  nav: [
    { id: "home",  label: "Home",  icon: "home",  href: "/" },
    { id: "connect",label: "Connect",icon: "connect",href: "/connect" },
    { id: "create", label: "Create", icon: "plus",  href: "/create" },
    { id: "discover",label:"Discover",icon: "search",href: "/discover" },
    { id: "profile",label: "Profile",icon: "user",  href: "/profile" }
  ]
} as const;

export type UniFedTokens = typeof tokens;
