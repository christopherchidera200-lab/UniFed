import { useState } from "react";
import { Menu } from "lucide-react";
import { BottomNav } from "./BottomNav";
import { ThemeToggle } from "@/components/theme/ThemeToggle";
import { NavDrawer } from "./NavDrawer";
import { SessionToast } from "@/components/SessionToast";

/** App chrome: top bar (logo + menu + theme toggle) + content + drawer + bottom nav + session toast. */
export function UniFedLayout({ children }: { children: React.ReactNode }) {
  const [drawerOpen, setDrawerOpen] = useState(false);
  return (
    <div className="min-h-screen bg-navy-50 dark:bg-navy-950 text-ink dark:text-navy-50 font-body antialiased">
      <header className="sticky top-0 z-40 h-14 flex items-center justify-between px-4
                         bg-white/80 dark:bg-navy-900/80 backdrop-blur-xl
                         border-b border-navy-100 dark:border-navy-800">
        <span className="font-display font-bold text-lg tracking-tight">
          Uni<span className="text-saffron-500">Fed</span>
        </span>
        <div className="flex items-center gap-1">
          <button
            type="button"
            aria-label="Open menu"
            onClick={() => setDrawerOpen(true)}
            className="grid h-9 w-9 place-items-center rounded-lg hover:bg-navy-100 dark:hover:bg-navy-800"
          >
            <Menu size={20} />
          </button>
          <ThemeToggle />
        </div>
      </header>

      <main className="mx-auto w-full max-w-2xl px-4 pb-24 pt-4">{children}</main>

      <BottomNav />
      <NavDrawer open={drawerOpen} onClose={() => setDrawerOpen(false)} />
      <SessionToast />
    </div>
  );
}
