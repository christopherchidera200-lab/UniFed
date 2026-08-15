import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { FileText, Send, Plus, CheckCircle2, AlertTriangle } from "lucide-react";
import { unifedApi, getToken, type AssignmentDTO, type ProfileDTO } from "@/lib/api";
import { SectionHeader, Card, IconBadge } from "@/components/ui/Card";
import { RequireAuth } from "@/components/auth/RequireAuth";

function formatDue(dueAt: string | null) {
  if (!dueAt) return "No due date";
  const d = new Date(dueAt);
  return d.toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });
}

export default function AssignmentsPage() {
  const token = getToken();
  const qc = useQueryClient();

  const profile = useQuery<ProfileDTO>({
    queryKey: ["profile"], queryFn: () => unifedApi.profile(token), enabled: Boolean(token)
  });
  const isLecturer = profile.data?.actor_type === "staff" || profile.data?.actor_type === "admin";

  const assignments = useQuery<AssignmentDTO[]>({
    queryKey: ["assignments", isLecturer],
    queryFn: () => unifedApi.assignments(token),
    enabled: Boolean(token)
  });

  return (
    <RequireAuth>
      <div className="space-y-6">
        <SectionHeader title="Assignments" eyebrow="LMS — coursework & submissions" />

        {isLecturer ? (
          <LecturerView token={token} assignments={assignments} qc={qc} />
        ) : (
          <StudentView token={token} assignments={assignments} qc={qc} />
        )}
      </div>
    </RequireAuth>
  );
}

function StudentView({
  token, assignments, qc
}: { token: string; assignments: ReturnType<typeof useQuery<AssignmentDTO[]>>; qc: ReturnType<typeof useQueryClient> }) {
  return (
    <Card className="divide-y divide-navy-50 dark:divide-navy-800/60 p-0">
      {assignments.data?.map((a) => (
        <div key={a.id} className="px-4 py-3 space-y-2">
          <div className="flex items-start gap-3">
            <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
              <FileText size={18} />
            </IconBadge>
            <div className="flex-1 min-w-0">
              <div className="font-medium text-ink">{a.title}</div>
              <div className="text-ink-subtle text-xs">Due {formatDue(a.due_at)}</div>
              {a.description && <div className="text-ink-muted text-xs mt-1">{a.description}</div>}
            </div>
            <div className="text-right text-xs text-ink-muted">
              <div>/ {a.max_score ?? "?"}</div>
            </div>
          </div>
          <StudentSubmit token={token} assignment={a} qc={qc} />
        </div>
      ))}
      {assignments.isLoading && <p className="px-4 py-3 text-ink-muted text-sm">Loading…</p>}
      {assignments.data?.length === 0 && (
        <p className="px-4 py-3 text-ink-muted text-sm">No assignments for your courses yet.</p>
      )}
    </Card>
  );
}

function StudentSubmit({
  token, assignment, qc
}: { token: string; assignment: AssignmentDTO; qc: ReturnType<typeof useQueryClient> }) {
  const [body, setBody] = useState("");
  const [open, setOpen] = useState(false);
  const submit = useMutation({
    mutationFn: () => unifedApi.submitAssignment(token, assignment.id, body),
    onSuccess: () => {
      setBody(""); setOpen(false);
      qc.invalidateQueries({ queryKey: ["assignments"] });
    }
  });

  if (assignment.my_submission) {
    const s = assignment.my_submission;
    return (
      <div className="flex items-center gap-2 text-xs text-emerald-600 dark:text-emerald-400">
        <CheckCircle2 size={14} />
        {s.status === "graded"
          ? `Graded ${s.score}/${assignment.max_score}`
          : `Submitted (${s.status})`}
      </div>
    );
  }

  return (
    <div>
      {open ? (
        <div className="space-y-2">
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Your answer / submission link…"
            rows={3}
            className="w-full resize-none rounded-xl border border-navy-100 dark:border-navy-800 bg-white dark:bg-navy-950 p-3 text-sm text-ink outline-none focus:border-saffron-400 focus:ring-2 focus:ring-saffron-200 dark:focus:ring-saffron-500/30"
          />
          {submit.isError && (
            <p className="flex items-center gap-1.5 text-xs text-amber-700 dark:text-amber-300">
              <AlertTriangle size={13} /> {(submit.error as Error)?.message}
            </p>
          )}
          <div className="flex gap-2">
            <button
              onClick={() => submit.mutate()}
              disabled={!body.trim() || submit.isPending}
              className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-md bg-navy-600 text-white font-medium hover:bg-navy-700 disabled:opacity-50"
            >
              <Send size={13} /> {submit.isPending ? "Submitting…" : "Submit"}
            </button>
            <button onClick={() => setOpen(false)} className="text-xs px-3 py-1.5 text-ink-muted">
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <button
          onClick={() => setOpen(true)}
          className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-md border border-navy-200 dark:border-navy-700 text-navy-600 dark:text-navy-200 hover:bg-navy-50 dark:hover:bg-navy-800"
        >
          <Send size={13} /> Submit work
        </button>
      )}
    </div>
  );
}

function LecturerView({
  token, assignments, qc
}: { token: string; assignments: ReturnType<typeof useQuery<AssignmentDTO[]>>; qc: ReturnType<typeof useQueryClient> }) {
  const [title, setTitle] = useState("");
  const [courseOfferingId, setCourseOfferingId] = useState("");
  const [dueAt, setDueAt] = useState("");
  const [expanded, setExpanded] = useState(false);
  const create = useMutation({
    mutationFn: () => unifedApi.createAssignment(token, {
      course_offering_id: courseOfferingId,
      title,
      due_at: dueAt || undefined
    }),
    onSuccess: () => {
      setTitle(""); setCourseOfferingId(""); setDueAt(""); setExpanded(false);
      qc.invalidateQueries({ queryKey: ["assignments"] });
    }
  });

  return (
    <>
      <Card>
        {expanded ? (
          <div className="space-y-3">
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Assignment title"
              className="w-full rounded-xl border border-navy-100 dark:border-navy-800 bg-white dark:bg-navy-950 p-2.5 text-sm text-ink outline-none focus:border-saffron-400 focus:ring-2 focus:ring-saffron-200 dark:focus:ring-saffron-500/30"
            />
            <input
              value={courseOfferingId}
              onChange={(e) => setCourseOfferingId(e.target.value)}
              placeholder="Course offering ID"
              className="w-full rounded-xl border border-navy-100 dark:border-navy-800 bg-white dark:bg-navy-950 p-2.5 text-sm text-ink outline-none focus:border-saffron-400 focus:ring-2 focus:ring-saffron-200 dark:focus:ring-saffron-500/30"
            />
            <input
              value={dueAt}
              onChange={(e) => setDueAt(e.target.value)}
              type="datetime-local"
              className="w-full rounded-xl border border-navy-100 dark:border-navy-800 bg-white dark:bg-navy-950 p-2.5 text-sm text-ink outline-none focus:border-saffron-400 focus:ring-2 focus:ring-saffron-200 dark:focus:ring-saffron-500/30"
            />
            {create.isError && (
              <p className="flex items-center gap-1.5 text-xs text-amber-700 dark:text-amber-300">
                <AlertTriangle size={13} /> {(create.error as Error)?.message}
              </p>
            )}
            <div className="flex gap-2">
              <button
                onClick={() => create.mutate()}
                disabled={!title.trim() || !courseOfferingId.trim() || create.isPending}
                className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-md bg-navy-600 text-white font-medium hover:bg-navy-700 disabled:opacity-50"
              >
                <Plus size={13} /> {create.isPending ? "Creating…" : "Create"}
              </button>
              <button onClick={() => setExpanded(false)} className="text-xs px-3 py-1.5 text-ink-muted">
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <button
            onClick={() => setExpanded(true)}
            className="flex items-center gap-2 text-sm font-medium text-navy-600 dark:text-navy-200"
          >
            <Plus size={16} /> New assignment
          </button>
        )}
      </Card>

      <Card className="divide-y divide-navy-50 dark:divide-navy-800/60 p-0">
        {assignments.data?.map((a) => (
          <div key={a.id} className="flex items-center justify-between gap-3 px-4 py-3">
            <div className="flex items-center gap-3">
              <IconBadge className="bg-brand-100 text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
                <FileText size={18} />
              </IconBadge>
              <div>
                <div className="font-medium text-ink">{a.title}</div>
                <div className="text-ink-subtle text-xs">
                  {a.published ? "Published" : "Draft"} · Due {formatDue(a.due_at)}
                </div>
              </div>
            </div>
            <span className="text-xs text-ink-muted">/ {a.max_score ?? "?"}</span>
          </div>
        ))}
        {assignments.isLoading && <p className="px-4 py-3 text-ink-muted text-sm">Loading…</p>}
        {assignments.data?.length === 0 && (
          <p className="px-4 py-3 text-ink-muted text-sm">No assignments created yet.</p>
        )}
      </Card>
    </>
  );
}
