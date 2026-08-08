import { useRouter } from "next/router";
import {
  Home, Users, Plus, Compass, User, type LucideIcon
} from "lucide-react";
import { tokens } from "@/design/tokens";
import { cn } from "@/lib/cn";

// Map token icon names -> lucide components.
const ICONS: Record<string, LucideIcon> = {
  home: Home, users: Users, plus: Plus, compass: Compass, user: User
};

/** The mandated 5-tab bottom navigation (mobile-first). Highlights the
 *  active route and swaps emoji -> lucide icons per the design upgrade. */
export function BottomNav() {
  const router = useRouter();
  return (
    <nav
      aria-label="Primary"
      className="fixed bottom-0 inset-x-0 z-40 flex items-center justify-around
                 h-16 px-2 bg-white/85 dark:bg-navy-900/85 backdrop-blur-xl
                 border-t border-navy-100 dark:border-navy-800 md:hidden"
    >
      {tokens.nav.map((item) => {
        const Icon = ICONS[item.icon] ?? Home;
        const active =
          item.href === "/"
            ? router.pathname === "/"
            : router.pathname.startsWith(item.href);
        return (
          <a
            key={item.id}
            href={item.href}
            aria-current={active ? "page" : undefined}
            className={cn(
              "flex flex-col items-center gap-1 text-xs font-medium transition-colors",
              active
                ? "text-saffron-600 dark:text-saffron-400"
                : "text-ink-muted hover:text-navy-600 dark:hover:text-navy-200"
            )}
          >
            <Icon size={20} strokeWidth={active ? 2.4 : 2} />
            <span>{item.label}</span>
          </a>
        );
      })}
    </nav>
  );
}
