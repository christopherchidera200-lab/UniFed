import { cn } from "@/lib/cn";

/**
 * Role badge — distinct treatment per actor role, visible in profile cards,
 * post authorship, and notifications. Academic identity, not just "user".
 */
export type ActorRole =
  | "student" | "lecturer" | "deptadmin" | "sysadmin" | "admin" | (string & {});

const ROLE_KEY: Record<string, string> = {
  student: "student", lecturer: "lecturer",
  deptadmin: "deptadmin", sysadmin: "sysadmin", admin: "sysadmin"
};
const ROLE_LABEL: Record<string, string> = {
  student: "Student", lecturer: "Lecturer",
  deptadmin: "Dept Admin", sysadmin: "Sys Admin", admin: "Sys Admin"
};

export function RoleBadge({
  role, className
}: { role?: string | null; className?: string }) {
  const key = ROLE_KEY[(role ?? "").toLowerCase()] ?? "student";
  const label = ROLE_LABEL[key] ?? (role ? role[0].toUpperCase() + role.slice(1) : "Member");
  return (
    <span
      className={cn(
        "rounded-pill px-2 py-0.5 text-[9px] font-extrabold uppercase tracking-wide text-white",
        `bg-role-${key}`,
        className
      )}
    >
      {label}
    </span>
  );
}
