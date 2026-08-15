import { useQuery } from "@tanstack/react-query";
import { GraduationCap, AlertTriangle } from "lucide-react";
import { unifedApi, getToken } from "@/lib/api";
import { SectionHeader, IconBadge, Card } from "@/components/ui/Card";
import { RequireAuth } from "@/components/auth/RequireAuth";

/** Slice-1 screen: a student's academic records + CGPA summary. */
export default function AcademicRecordsPage() {
  const token = getToken();

  // Resolve the authenticated user's own student identity (no hardcoded id).
  const me = useQuery({
    queryKey: ["academic-me"],
    queryFn: () => unifedApi.myStudent(token),
    enabled: Boolean(token)
  });

  const studentId = me.data?.id;
  const universityId = me.data?.university_id;

  const records = useQuery({
    queryKey: ["records", studentId],
    queryFn: () => unifedApi.records(universityId as string, studentId as string, token),
    enabled: Boolean(studentId && universityId && token)
  });
  const summary = useQuery({
    queryKey: ["summary", studentId],
    queryFn: () => unifedApi.summary(universityId as string, studentId as string, token),
    enabled: Boolean(studentId && universityId && token)
  });

  const matricNo = me.data?.matric_no;

  return (
    <RequireAuth>
    <div className="space-y-6">
      <SectionHeader
        title="Academic Records"
        eyebrow={`${matricNo ?? "—"} · CGPA `}
        action={
          <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
            <GraduationCap size={18} />
          </IconBadge>
        }
      />
      <p className="text-ink-muted -mt-3 text-sm">
        Cumulative GPA{" "}
        <span className="font-semibold text-saffron-600">
          {summary.data?.cgpa?.toFixed(2) ?? "—"}
        </span>
      </p>

      {me.isLoading && <p className="text-ink-muted text-sm">Loading your records…</p>}
      {me.isError && (
        <Card className="flex items-center gap-3 border-amber-300 text-amber-700 dark:border-amber-500/40 dark:text-amber-300">
          <AlertTriangle size={18} />
          <span className="text-sm">Could not load your academic identity.</span>
        </Card>
      )}
      {me.data && !studentId && (
        <Card className="flex items-center gap-3 border-amber-300 text-amber-700 dark:border-amber-500/40 dark:text-amber-300">
          <AlertTriangle size={18} />
          <span className="text-sm">No academic record is linked to your account yet.</span>
        </Card>
      )}

      <Card className="overflow-hidden p-0">
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
      </Card>
    </div>
    </RequireAuth>
  );
}
