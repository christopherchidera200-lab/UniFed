import type { ReactNode } from "react";
import type { ReactElement } from "react";

/** Typed API client for the UniFed Rails backend (slice-1 endpoints). */
const BASE = process.env.NEXT_PUBLIC_API_BASE ?? "https://api.unifed.ng";

export interface GradeRecordDTO {
  course_code: string;
  course_title: string;
  credit_units: number;
  score: number | null;
  grade_letter: string | null;
  grade_point: number | null;
  semester: number;
}

export interface SummaryDTO {
  matric_no: string;
  cgpa: number | null;
  total_credits: number | null;
  class_of_degree: string | null;
}

async function authedFetch<T>(path: string, token: string): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    headers: { Authorization: `Bearer ${token}`, Accept: "application/json" }
  });
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json() as Promise<T>;
}

export const unifedApi = {
  records: (studentId: string, token: string) =>
    authedFetch<GradeRecordDTO[]>(`/api/v1/academic/students/${studentId}/records`, token),
  summary: (studentId: string, token: string) =>
    authedFetch<SummaryDTO>(`/api/v1/academic/students/${studentId}/summary`, token)
};

export function withLayout(page: ReactNode): ReactElement {
  return <>{page}</>;
}
