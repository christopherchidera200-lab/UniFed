import { BottomNav } from "./BottomNav";
import { ThemeToggle } from "@/components/theme/ThemeToggle";

/** App chrome: top bar (logo + theme toggle) + content + persistent bottom nav. */
export function UniFedLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-navy-50 dark:bg-navy-950 text-ink dark:text-navy-50 font-body antialiased">
      <header className="sticky top-0 z-40 h-14 flex items-center justify-between px-4
                         bg-white/80 dark:bg-navy-900/80 backdrop-blur-xl
                         border-b border-navy-100 dark:border-navy-800">
        <span className="font-display font-bold text-lg tracking-tight">
          Uni<span className="text-saffron-500">Fed</span>
        </span>
        <ThemeToggle />
      </header>

      <main className="mx-auto w-full max-w-2xl px-4 pb-24 pt-4">{children}</main>

      <BottomNav />
    </div>
  );
}
