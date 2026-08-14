import { useQuery } from "@tanstack/react-query";
import { User, Mail, GraduationCap, LogOut, AlertTriangle } from "lucide-react";
import { unifedApi, getToken, type ProfileDTO } from "@/lib/api";
import { logout } from "@/lib/auth";
import { SectionHeader, Card, IconBadge } from "@/components/ui/Card";
import { RequireAuth } from "@/components/auth/RequireAuth";

/** Profile — the authenticated user's real identity + quick actions. */
export default function ProfilePage() {
  const token = getToken();

  const profile = useQuery<ProfileDTO>({
    queryKey: ["profile"],
    queryFn: () => unifedApi.profile(token),
    enabled: Boolean(token)
  });

  const displayName = profile.data?.display_name || "UniFed User";
  const email = profile.data?.email;

  return (
    <RequireAuth>
      <div className="space-y-6">
        <SectionHeader title="Profile" eyebrow="Your UniFed identity" />

        {profile.isLoading && (
          <Card className="px-4 py-3 text-ink-muted text-sm">Loading your profile…</Card>
        )}

        {profile.isError && (
          <Card className="flex items-center gap-3 border-amber-300 text-amber-700 dark:border-amber-500/40 dark:text-amber-300">
            <AlertTriangle size={18} />
            <span className="text-sm">Could not load your profile. Please try again.</span>
          </Card>
        )}

        {profile.data && (
          <>
            <Card className="flex items-center gap-4">
              <span className="grid h-14 w-14 place-items-center rounded-2xl bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300">
                <User size={26} />
              </span>
              <div>
                <div className="font-display font-bold text-lg text-ink">{displayName}</div>
                <div className="text-ink-muted text-sm">{email}</div>
                {profile.data.actor_type && (
                  <div className="text-ink-subtle text-xs mt-0.5 capitalize">
                    {profile.data.actor_type}
                  </div>
                )}
              </div>
            </Card>

            {(profile.data.bio || (profile.data.skills && profile.data.skills.length > 0)) && (
              <Card className="space-y-3">
                {profile.data.bio && (
                  <div>
                    <div className="font-medium text-ink text-sm">About</div>
                    <div className="text-ink-subtle text-xs">{profile.data.bio}</div>
                  </div>
                )}
                {profile.data.skills && profile.data.skills.length > 0 && (
                  <div>
                    <div className="font-medium text-ink text-sm">Skills</div>
                    <div className="flex flex-wrap gap-1.5 mt-1">
                      {profile.data.skills.map((s) => (
                        <span
                          key={s}
                          className="text-xs px-2 py-0.5 rounded-pill bg-brand-100 text-brand-700 dark:bg-brand-500/20 dark:text-brand-300"
                        >
                          {s}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </Card>
            )}

            <div className="space-y-3">
              <Card className="flex items-center gap-3">
                <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
                  <GraduationCap size={18} />
                </IconBadge>
                <div className="flex-1">
                  <div className="font-medium text-ink">Account</div>
                  <div className="text-ink-subtle text-xs">
                    {email ? "Connected via your university account" : "No email on file"}
                  </div>
                </div>
              </Card>
              <Card className="flex items-center gap-3">
                <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
                  <Mail size={18} />
                </IconBadge>
                <div className="flex-1">
                  <div className="font-medium text-ink">University</div>
                  <div className="text-ink-subtle text-xs">adun · ADUN</div>
                </div>
              </Card>
            </div>
          </>
        )}

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
    </RequireAuth>
  );
}
