import { useState, type ReactNode } from "react";
import Link from "next/link";
import { useRouter } from "next/router";
import {
  Home, GraduationCap, FlaskConical, Bell, Briefcase, BookOpen,
  MapPin, CalendarDays, ShieldCheck, Plus, X, Compass, Users
} from "lucide-react";
import { cn } from "@/lib/cn";
import { useQuery } from "@tanstack/react-query";
import { unifedApi, getToken, type ProfileDTO } from "@/lib/api";

/**
 * Slide-out primary nav (Mastodon pattern, endorsed by the brief).
 * Academic surfaces route through here; the 5-tab bar stays for thumb reach.
 * The Administration group renders ONLY when actor_type === "admin" (defense
 * in depth on top of RequireAuth + server RBAC).
 */
interface NavItem { href: string; label: string; icon: ReactNode; adminOnly?: boolean; }

const CORE: NavItem[] = [
  { href: "/", label: "Home / Campus Feed", icon: <Home size={18} /> },
  { href: "/assignments", label: "Assignments", icon: <GraduationCap size={18} /> },
  { href: "/research", label: "Research", icon: <FlaskConical size={18} /> },
  { href: "/notifications", label: "Notifications", icon: <Bell size={18} /> }
];
const SECONDARY: NavItem[] = [
  { href: "/career", label: "Career", icon: <Briefcase size={18} /> },
  { href: "/library", label: "Library", icon: <BookOpen size={18} /> },
  { href: "/campus", label: "Smart Campus", icon: <MapPin size={18} /> },
  { href: "/events", label: "Events", icon: <CalendarDays size={18} /> },
  { href: "/discover", label: "Discover", icon: <Compass size={18} /> },
  { href: "/connect", label: "Connect", icon: <Users size={18} /> }
];
const ADMIN: NavItem[] = [
  { href: "/admin", label: "Administration", icon: <ShieldCheck size={18} />, adminOnly: true }
];

export function NavDrawer({ open, onClose }: { open: boolean; onClose: () => void }) {
  const router = useRouter();
  const token = getToken();
  const { data: profile } = useQuery<ProfileDTO>({
    queryKey: ["profile"],
    queryFn: () => unifedApi.profile(token),
    enabled: Boolean(token)
  });
  const isAdmin = profile?.actor_type === "admin";

  const items = [...CORE, ...SECONDARY, ...(isAdmin ? ADMIN : [])];

  return (
    <>
      {open ? <div className="fixed inset-0 z-50 bg-black/40" onClick={onClose} aria-hidden /> : null}
      <aside
        className={cn(
          "fixed right-0 top-0 bottom-0 z-50 w-[80%] max-w-xs bg-white dark:bg-navy-900 shadow-lift transition-transform duration-200",
          open ? "translate-x-0" : "translate-x-full"
        )}
        aria-hidden={!open}
      >
        <div className="flex items-center justify-between p-4 border-b border-navy-100 dark:border-navy-800">
          <span className="font-display font-bold text-lg">Menu</span>
          <button type="button" onClick={onClose} aria-label="Close menu" className="iconbtn">
            <X size={18} />
          </button>
        </div>

        <div className="p-3">
          <Link
            href="/create"
            onClick={onClose}
            className="mb-3 flex items-center justify-center gap-2 rounded-2xl bg-saffron-500 px-4 py-3 font-extrabold text-[#1a1003]"
          >
            <Plus size={18} /> New Post
          </Link>

          <p className="px-2 pb-1 pt-2 text-[11px] font-semibold uppercase tracking-wide text-ink-subtle">Core</p>
          {CORE.map((it) => <DrawerLink key={it.href} it={it} active={router.pathname === it.href} onClick={onClose} />)}

          <p className="px-2 pb-1 pt-3 text-[11px] font-semibold uppercase tracking-wide text-ink-subtle">Secondary</p>
          {SECONDARY.map((it) => <DrawerLink key={it.href} it={it} active={router.pathname === it.href} onClick={onClose} />)}

          {isAdmin ? (
            <>
              <p className="px-2 pb-1 pt-3 text-[11px] font-semibold uppercase tracking-wide text-saffron-600">Administration</p>
              {ADMIN.map((it) => <DrawerLink key={it.href} it={it} active={router.pathname === it.href} onClick={onClose} />)}
            </>
          ) : null}
        </div>
      </aside>
    </>
  );
}

function DrawerLink({ it, active, onClick }: { it: NavItem; active: boolean; onClick: () => void }) {
  return (
    <Link
      href={it.href}
      onClick={onClick}
      className={cn(
        "flex items-center gap-3 rounded-xl px-3 py-2.5 font-semibold text-sm",
        active ? "bg-navy-100 dark:bg-navy-800 text-navy-700 dark:text-navy-100"
               : "text-ink dark:text-navy-200 hover:bg-navy-50 dark:hover:bg-navy-800/60"
      )}
    >
      <span className={it.adminOnly ? "text-saffron-600" : ""}>{it.icon}</span>
      {it.label}
    </Link>
  );
}
