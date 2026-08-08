import { User, Mail, GraduationCap, LogOut } from "lucide-react";
import { getToken } from "@/lib/api";
import { logout } from "@/lib/auth";
import { SectionHeader, Card, IconBadge } from "@/components/ui/Card";

/** Profile — student identity + quick actions. Logout clears the session. */
export default function ProfilePage() {
  const token = getToken();

  return (
    <div className="space-y-6">
      <SectionHeader title="Profile" eyebrow="Your UniFed identity" />

      <Card className="flex items-center gap-4">
        <span className="grid h-14 w-14 place-items-center rounded-2xl bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300">
          <User size={26} />
        </span>
        <div>
          <div className="font-display font-bold text-lg text-ink">ADUN Student</div>
          <div className="text-ink-muted text-sm">student@adun.edu.ng</div>
        </div>
      </Card>

      <div className="space-y-3">
        <Card className="flex items-center gap-3">
          <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
            <GraduationCap size={18} />
          </IconBadge>
          <div className="flex-1">
            <div className="font-medium text-ink">Programme</div>
            <div className="text-ink-subtle text-xs">B.Sc. Computer Science · 300L</div>
          </div>
        </Card>
        <Card className="flex items-center gap-3">
          <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
            <Mail size={18} />
          </IconBadge>
          <div className="flex-1">
            <div className="font-medium text-ink">University</div>
            <div className="text-ink-subtle text-xs">ADUN · adun</div>
          </div>
        </Card>
      </div>

      <button
        onClick={() => logout()}
        disabled={!token}
        className="w-full flex items-center justify-center gap-2 text-sm px-4 py-2.5 rounded-md
                   border border-navy-200 dark:border-navy-700 font-medium text-ink
                   hover:bg-navy-50 dark:hover:bg-navy-800 transition-colors disabled:opacity-50"
      >
        <LogOut size={16} /> Sign out
      </button>
    </div>
  );
}
