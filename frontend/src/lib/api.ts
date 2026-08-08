/** Typed API client for the UniFed Rails backend. */
const BASE = process.env.NEXT_PUBLIC_API_BASE ?? "https://api.unifed.ng";

import { getToken as getTokenFromAuth } from "./auth";

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

export interface CourseDTO {
  id: string;
  code: string;
  title: string;
  credit_units: number;
  level: number;
  semester: number;
  programme_id: string;
  prerequisites: string[] | null;
}

export interface OfferingDTO {
  id: string;
  course_code: string;
  course_title: string;
  semester_number: number;
  lecturer: string | null;
}

export interface EventDTO {
  id: string;
  title: string;
  type: string;
  event_start: string;
  event_end: string | null;
  faculty_id: string | null;
  department_id: string | null;
}

export interface OpportunityDTO {
  id: string;
  title: string;
  employment_type: string;
  location_type: string | null;
  location: string | null;
  remote: boolean | null;
  min_level: number | null;
  salary_range: string | null;
  employer: string | null;
  created_at: string;
}

export interface ApplicationDTO {
  id: string;
  status: string;
  opportunity: OpportunityDTO;
}

async function authedFetch<T>(path: string, token: string): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    headers: { Authorization: `Bearer ${token}`, Accept: "application/json" }
  });
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json() as Promise<T>;
}

async function authedPost<T>(path: string, token: string, body: unknown): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    body: JSON.stringify(body)
  });
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json() as Promise<T>;
}

export const unifedApi = {
  records: (studentId: string, token: string) =>
    authedFetch<GradeRecordDTO[]>(`/api/v1/academic/students/${studentId}/records`, token),
  summary: (studentId: string, token: string) =>
    authedFetch<SummaryDTO>(`/api/v1/academic/students/${studentId}/summary`, token),

  // Phase 2 — Catalog
  catalogCourses: (token: string, params: Record<string, string | number> = {}) => {
    const qs = new URLSearchParams(params as Record<string, string>).toString();
    return authedFetch<CourseDTO[]>(`/api/v1/catalog/courses?${qs}`, token);
  },
  catalogOfferings: (token: string, academicSessionId: string) =>
    authedFetch<OfferingDTO[]>(
      `/api/v1/catalog/offerings?academic_session_id=${encodeURIComponent(academicSessionId)}`,
      token
    ),

  // Phase 2 — Events / Calendar
  events: (token: string, params: Record<string, string> = {}) => {
    const qs = new URLSearchParams(params).toString();
    return authedFetch<EventDTO[]>(`/api/v1/calendar/events?${qs}`, token);
  },

  // Phase 2 — Career Hub
  opportunities: (token: string, params: Record<string, string> = {}) => {
    const qs = new URLSearchParams(params).toString();
    return authedFetch<OpportunityDTO[]>(`/api/v1/career/opportunities?${qs}`, token);
  },
  recommendations: (token: string) =>
    authedFetch<OpportunityDTO[]>(`/api/v1/career/recommendations`, token),
  applications: (token: string) =>
    authedFetch<ApplicationDTO[]>(`/api/v1/career/applications`, token),
  apply: (token: string, id: string, coverNote?: string) =>
    authedPost<{ application_id: string; status: string }>(
      `/api/v1/career/opportunities/${id}/apply`,
      token,
      { cover_note: coverNote }
    ),
  saveJob: (token: string, id: string) =>
    authedPost<{ saved: boolean }>(`/api/v1/career/opportunities/${id}/save`, token, {})
};

/** Resolve the OIDC bearer token via the shared auth store. */
export function getToken(): string {
  return getTokenFromAuth();
}
