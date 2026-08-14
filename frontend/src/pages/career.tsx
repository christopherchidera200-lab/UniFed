import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Briefcase, MapPin } from "lucide-react";
import { unifedApi, getToken, type OpportunityDTO } from "@/lib/api";
import { SectionHeader, IconBadge, Card } from "@/components/ui/Card";

/** Career Hub (Phase 2): browse opportunities, apply, and save. */
export default function CareerPage() {
  const token = getToken();
  const qc = useQueryClient();

  const opportunities = useQuery<OpportunityDTO[]>({
    queryKey: ["opportunities"],
    queryFn: () => unifedApi.opportunities(token),
    enabled: Boolean(token)
  });

  const apply = useMutation({
    mutationFn: (id: string) => unifedApi.apply(token, id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["applications"] })
  });
  const save = useMutation({
    mutationFn: (id: string) => unifedApi.saveJob(token, id)
  });

  return (
    <>
      <div className="space-y-6">
        <SectionHeader title="Career Hub" eyebrow="Internships, graduate roles & gigs" />
        <div className="space-y-3">
          {opportunities.data?.map((o: OpportunityDTO) => (
            <Card key={o.id}>
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-start gap-3">
                  <IconBadge className="bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300">
                    <Briefcase size={18} />
                  </IconBadge>
                  <div>
                    <div className="font-semibold text-ink">{o.title}</div>
                    <div className="text-ink-subtle text-xs">
                      {o.employer ?? "Employer"} · {o.employment_type}
                    </div>
                    {o.location && (
                      <div className="text-ink-muted text-xs mt-0.5 flex items-center gap-1">
                        <MapPin size={12} /> {o.location}
                      </div>
                    )}
                  </div>
                </div>
                <span className="text-xs px-2 py-0.5 rounded-pill bg-saffron-100 text-saffron-700 dark:bg-saffron-500/20 dark:text-saffron-300">
                  {o.salary_range ?? "—"}
                </span>
              </div>
              <div className="mt-3 flex gap-2">
                <button
                  onClick={() => apply.mutate(o.id)}
                  className="text-sm px-3 py-1.5 rounded-md bg-navy-600 text-white font-medium
                             hover:bg-navy-700 transition-colors"
                >
                  Apply
                </button>
                <button
                  onClick={() => save.mutate(o.id)}
                  className="text-sm px-3 py-1.5 rounded-md border border-navy-200 dark:border-navy-700
                             font-medium hover:bg-navy-50 dark:hover:bg-navy-800 transition-colors"
                >
                  Save
                </button>
              </div>
            </Card>
          ))}
          {opportunities.isLoading && <p className="text-ink-muted text-sm">Loading…</p>}
          {opportunities.data?.length === 0 && (
            <p className="text-ink-muted text-sm">No open opportunities right now.</p>
          )}
        </div>
      </div>
    </>
  );
}
