import { useQuery } from "@tanstack/react-query";
import { BookOpen } from "lucide-react";
import { unifedApi, getToken, type CourseDTO } from "@/lib/api";
import { Card, SectionHeader, IconBadge } from "@/components/ui/Card";

/** Course Catalogue browser (Phase 2). Bento list of courses. */
export default function CatalogPage() {
  const token = getToken();
  const q = "";
  const courses = useQuery<CourseDTO[]>({
    queryKey: ["catalog-courses", q],
    queryFn: () => unifedApi.catalogCourses(token, q ? { q } : {}),
    enabled: Boolean(token)
  });

  return (
    <>
      <div className="space-y-6">
        <SectionHeader title="Course Catalogue" eyebrow="Browse ADUN offerings" />
        <Card className="divide-y divide-navy-50 dark:divide-navy-800/60 p-0">
          {courses.data?.map((c: CourseDTO) => (
            <div key={c.id} className="flex items-center justify-between gap-3 px-4 py-3">
              <div className="flex items-center gap-3">
                <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
                  <BookOpen size={18} />
                </IconBadge>
                <div>
                  <div className="font-semibold text-ink">{c.code}</div>
                  <div className="text-ink-subtle text-xs">{c.title}</div>
                </div>
              </div>
              <div className="text-right text-xs text-ink-muted">
                <div>{c.credit_units} units</div>
                <div>L{c.level} · Sem {c.semester}</div>
              </div>
            </div>
          ))}
          {courses.isLoading && <p className="px-4 py-3 text-ink-muted text-sm">Loading…</p>}
          {courses.data?.length === 0 && (
            <p className="px-4 py-3 text-ink-muted text-sm">No courses found.</p>
          )}
        </Card>
      </div>
    </>
  );
}
