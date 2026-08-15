import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Users, Search, GraduationCap, BookOpen } from "lucide-react";
import { unifedApi, type ResearchProfileDTO, type ResearchGroupDTO } from "@/lib/api";
import { SectionHeader, Card, IconBadge } from "@/components/ui/Card";

/** Research Hub — browse researcher profiles and groups (Phase 3). */
export default function ResearchPage() {
  const [q, setQ] = useState("");
  const profiles = useQuery<ResearchProfileDTO[]>({
    queryKey: ["research-profiles", q],
    queryFn: () => unifedApi.researchProfiles(q ? { q } : {}),
    enabled: true
  });
  const groups = useQuery<ResearchGroupDTO[]>({
    queryKey: ["research-groups"],
    queryFn: () => unifedApi.researchGroups(),
    enabled: true
  });

  const [openGroup, setOpenGroup] = useState<string | null>(null);
  const groupDetail = useQuery<ResearchGroupDTO & { member_ids: string[] }>({
    queryKey: ["research-group", openGroup],
    queryFn: () => unifedApi.researchGroup(openGroup as string),
    enabled: Boolean(openGroup)
  });

  return (
    <div className="space-y-6">
      <SectionHeader title="Research Hub" eyebrow="Discover people & groups" />

      <section className="space-y-3">
        <div className="relative">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-subtle" />
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search researchers by name, field, ORCID…"
            className="w-full rounded-xl border border-navy-100 dark:border-navy-800 bg-white dark:bg-navy-950 pl-9 pr-3 py-2.5 text-sm text-ink outline-none focus:border-saffron-400 focus:ring-2 focus:ring-saffron-200 dark:focus:ring-saffron-500/30"
          />
        </div>

        <Card className="divide-y divide-navy-50 dark:divide-navy-800/60 p-0">
          {profiles.data?.map((p) => (
            <div key={p.id} className="flex items-start gap-3 px-4 py-3">
              <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
                <GraduationCap size={18} />
              </IconBadge>
              <div className="flex-1 min-w-0">
                <div className="font-medium text-ink">{p.title || "Researcher"}</div>
                {p.research_fields && p.research_fields.length > 0 && (
                  <div className="flex flex-wrap gap-1.5 mt-1">
                    {p.research_fields.slice(0, 4).map((f) => (
                      <span key={f} className="text-[11px] px-2 py-0.5 rounded-pill bg-navy-100 dark:bg-navy-800 text-navy-600 dark:text-navy-200">
                        {f}
                      </span>
                    ))}
                  </div>
                )}
                <div className="text-ink-subtle text-xs mt-1">
                  {p.citations_count != null ? `${p.citations_count} citations` : "No citation data"}·
                  {p.orcid ? ` ORCID ${p.orcid}` : " No ORCID"}
                </div>
              </div>
            </div>
          ))}
          {profiles.isLoading && <p className="px-4 py-3 text-ink-muted text-sm">Searching…</p>}
          {profiles.data?.length === 0 && (
            <p className="px-4 py-3 text-ink-muted text-sm">No researcher profiles match.</p>
          )}
        </Card>
      </section>

      <section className="space-y-3">
        <SectionHeader title="Research Groups" eyebrow="Labs & projects" />
        <Card className="divide-y divide-navy-50 dark:divide-navy-800/60 p-0">
          {groups.data?.map((g) => (
            <button
              key={g.id}
              onClick={() => setOpenGroup((cur) => (cur === g.id ? null : g.id))}
              className="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-navy-50 dark:hover:bg-navy-800/50 transition-colors"
            >
              <IconBadge className="bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300">
                <Users size={18} />
              </IconBadge>
              <div className="flex-1">
                <div className="font-medium text-ink">{g.name}</div>
                {g.description && (
                  <div className="text-ink-subtle text-xs truncate">{g.description}</div>
                )}
              </div>
            </button>
          ))}
          {groups.isLoading && <p className="px-4 py-3 text-ink-muted text-sm">Loading…</p>}
          {groups.data?.length === 0 && (
            <p className="px-4 py-3 text-ink-muted text-sm">No research groups yet.</p>
          )}
        </Card>

        {openGroup && (
          <Card>
            {groupDetail.isLoading && <p className="text-ink-muted text-sm">Loading group…</p>}
            {groupDetail.data && (
              <div className="space-y-2">
                <div className="font-medium text-ink">{groupDetail.data.name}</div>
                {groupDetail.data.description && (
                  <div className="text-ink-muted text-sm">{groupDetail.data.description}</div>
                )}
                <div className="flex items-center gap-1.5 text-xs text-ink-muted">
                  <BookOpen size={13} /> {groupDetail.data.member_ids?.length ?? 0} members
                </div>
              </div>
            )}
          </Card>
        )}
      </section>
    </div>
  );
}
