import { Moon, Sun } from "lucide-react";
import { useTheme } from "@/components/theme/useTheme";
import { cn } from "@/lib/cn";

/** Light/dark theme toggle. Persists via useTheme (localStorage). */
export function ThemeToggle({ className }: { className?: string }) {
  const { theme, toggle } = useTheme();
  const isDark = theme === "dark";
  return (
    <button
      type="button"
      onClick={toggle}
      aria-label={isDark ? "Switch to light mode" : "Switch to dark mode"}
      className={cn(
        "grid h-9 w-9 place-items-center rounded-full border border-navy-100 bg-white text-ink-muted",
        "transition-colors hover:text-saffron-600 dark:border-navy-800 dark:bg-navy-900",
        className
      )}
    >
      {isDark ? <Sun size={18} /> : <Moon size={18} />}
    </button>
  );
}
