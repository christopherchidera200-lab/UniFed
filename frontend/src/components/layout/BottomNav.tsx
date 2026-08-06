import { tokens } from "@/design/tokens";

const nav = tokens.nav;

/** The mandated 5-tab bottom navigation (mobile-first). Persistent across the app. */
export function BottomNav() {
  return (
    <nav
      aria-label="Primary"
      className="fixed bottom-0 inset-x-0 z-40 flex items-center justify-around
                 h-16 px-2 bg-white/80 dark:bg-navy-900/80 backdrop-blur-xl
                 border-t border-navy-100 dark:border-navy-800 md:hidden"
    >
      {nav.map((item) => (
        <a
          key={item.id}
          href={item.href}
          className="flex flex-col items-center gap-1 text-xs font-medium
                     text-ink-muted hover:text-saffron-600 transition-colors"
        >
          <span aria-hidden className="text-lg">{glyph(item.icon)}</span>
          <span>{item.label}</span>
        </a>
      ))}
    </nav>
  );
}

function glyph(icon: string): string {
  // Lightweight inline glyphs; replace with an icon set (lucide) later.
  const map: Record<string, string> = {
    home: "🏠", connect: "💬", plus: "➕", search: "🔍", user: "👤"
  };
  return map[icon] ?? "•";
}
