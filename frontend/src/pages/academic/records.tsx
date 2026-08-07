import { useQuery } from "@tanstack/react-query";
import { unifedApi } from "@/lib/api";

/** Slice-1 screen: a student's academic records + CGPA summary.
 *  Mobile-first, accessible, premium. Token would come from the OIDC session. */
export default function AcademicRecordsPage() {
  const token = ""; // resolved from auth context in production
  const studentId = ""; // from route / selected student

  const records = useQuery({
    queryKey: ["records", studentId],
    queryFn: () => unifedApi.records(studentId, token),
    enabled: Boolean(studentId && token)
  });
  const summary = useQuery({
    queryKey: ["summary", studentId],
    queryFn: () => unifedApi.summary(studentId, token),
    enabled: Boolean(studentId && token)
  });

  return (
    <section className="space-y-6">
      <header>
        <h1 className="font-display text-2xl font-bold tracking-tight">Academic Records</h1>
        <p className="text-ink-muted text-sm">
          {summary.data?.matric_no ?? "—"} · CGPA{" "}
          <span className="font-semibold text-saffron-600">
            {summary.data?.cgpa?.toFixed(2) ?? "—"}
          </span>
        </p>
      </header>

      <div className="rounded-lg border border-navy-100 dark:border-navy-800 bg-white
                      dark:bg-navy-900/60 shadow-soft overflow-hidden">
        <table className="w-full text-sm">
          <thead className="text-ink-muted">
            <tr className="border-b border-navy-100 dark:border-navy-800">
              <th className="text-left py-2 px-3 font-medium">Course</th>
              <th className="text-right py-2 px-3 font-medium">Units</th>
              <th className="text-right py-2 px-3 font-medium">Score</th>
              <th className="text-right py-2 px-3 font-medium">Grade</th>
            </tr>
          </thead>
          <tbody>
            {records.data?.map((g) => (
              <tr key={g.course_code}
                  className="border-b border-navy-50 dark:border-navy-800/60 last:border-0">
                <td className="py-2 px-3">
                  <div className="font-medium">{g.course_code}</div>
                  <div className="text-ink-subtle text-xs">{g.course_title}</div>
                </td>
                <td className="text-right py-2 px-3">{g.credit_units}</td>
                <td className="text-right py-2 px-3">{g.score ?? "—"}</td>
                <td className="text-right py-2 px-3 font-semibold">{g.grade_letter ?? "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {records.isLoading && <p className="p-3 text-ink-muted text-sm">Loading…</p>}
        {records.data?.length === 0 && (
          <p className="p-3 text-ink-muted text-sm">No published results yet.</p>
        )}
      </div>
    </section>
  );
}
