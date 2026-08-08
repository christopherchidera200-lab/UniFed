import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { unifedApi, getToken, type OpportunityDTO } from "@/lib/api";

/** Career Hub (Phase 2): browse opportunities, apply, and save. */
export default function CareerPage() {
  const token = getToken();
  const qc = useQueryClient();

  const opportunities = useQuery({
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
    <section className="space-y-6">
      <header>
        <h1 className="font-display text-2xl font-bold tracking-tight">Career Hub</h1>
        <p className="text-ink-muted text-sm">Internships, graduate roles, and gigs.</p>
      </header>

      <div className="space-y-3">
        {opportunities.data?.map((o: OpportunityDTO) => (
          <article
            key={o.id}
            className="rounded-lg border border-navy-100 dark:border-navy-800 bg-white
                       dark:bg-navy-900/60 shadow-soft p-3"
          >
            <div className="flex items-start justify-between gap-3">
              <div>
                <div className="font-medium">{o.title}</div>
                <div className="text-ink-subtle text-xs">
                  {o.employer ?? "Employer"} · {o.employment_type}
                  {o.remote ? " · remote" : ""}
                </div>
              </div>
              <span className="text-xs px-2 py-0.5 rounded-pill bg-saffron-100 text-saffron-700">
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
          </article>
        ))}
        {opportunities.isLoading && <p className="text-ink-muted text-sm">Loading…</p>}
        {opportunities.data?.length === 0 && (
          <p className="text-ink-muted text-sm">No open opportunities right now.</p>
        )}
      </div>
    </section>
  );
}
