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

export interface LibraryResourceDTO {
  id: string;
  title: string;
  author: string | null;
  type: string;
  available: boolean;
}

export interface NotificationDTO {
  id: string;
  category: string;
  title: string;
  body: string | null;
  created_at: string;
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

export interface ProfileDTO {
  id: string;
  display_name: string | null;
  email: string;
  actor_type: string;
  bio: string | null;
  skills: string[];
  portfolio: string[];
  social_links: Record<string, string>;
  creator: boolean;
}

async function authedFetch<T>(path: string, token: string): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    headers: { Authorization: `Bearer ${token}`, Accept: "application/json" }
  });
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json() as Promise<T>;
}

// Public browse endpoints (catalog/library/events/career) require NO auth token.
async function publicFetch<T>(path: string): Promise<T> {
  const res = await fetch(`${BASE}${path}`, { headers: { Accept: "application/json" } });
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
  // --- Profile (authenticated; returns the CURRENT user's own profile) ---
  profile: (token: string) =>
    authedFetch<ProfileDTO>(`/api/v1/profile`, token),

  // --- Self-service registration (reuses the existing auth flow) ---
  register: async (payload: {
    name: string; email: string; password: string; matric_no?: string;
  }) => {
    const res = await fetch(`${BASE}/api/v1/auth/register`, {
      method: "POST",
      headers: { Accept: "application/json", "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      // Surface the server's machine-readable reason (e.g. email_taken, password_too_weak).
      throw new Error((data && (data.error || data.reason)) || `Registration failed (${res.status})`);
    }
    return data as { access_token: string; refresh_token: string; expires_in?: number };
  },

  records: (studentId: string, token: string) =>
    authedFetch<GradeRecordDTO[]>(`/api/v1/academic/students/${studentId}/records`, token),
  summary: (studentId: string, token: string) =>
    authedFetch<SummaryDTO>(`/api/v1/academic/students/${studentId}/summary`, token),

  // Phase 2 — Catalog (PUBLIC browse)
  catalogCourses: (params: Record<string, string | number> = {}) => {
    const qs = new URLSearchParams(params as Record<string, string>).toString();
    return publicFetch<CourseDTO[]>(`/api/v1/catalog/courses?${qs}`);
  },
  catalogOfferings: (academicSessionId: string) =>
    publicFetch<OfferingDTO[]>(
      `/api/v1/catalog/offerings?academic_session_id=${encodeURIComponent(academicSessionId)}`
    ),

  // Phase 2 — Events / Calendar (PUBLIC browse)
  events: (params: Record<string, string> = {}) => {
    const qs = new URLSearchParams(params).toString();
    return publicFetch<EventDTO[]>(`/api/v1/calendar/events?${qs}`);
  },

  // Phase 2 — Career Hub (opportunities PUBLIC browse; applications/auth'd)
  opportunities: (params: Record<string, string> = {}) => {
    const qs = new URLSearchParams(params).toString();
    return publicFetch<OpportunityDTO[]>(`/api/v1/career/opportunities?${qs}`);
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
  ,

  // Phase 2 depth — Library (resources PUBLIC browse; borrow/auth'd)
  libraryResources: (params: Record<string, string> = {}) => {
    const qs = new URLSearchParams(params).toString();
    return publicFetch<LibraryResourceDTO[]>(`/api/v1/library/resources?${qs}`);
  },

  // Phase 2 depth — Notifications
  notifications: (token: string) =>
    authedFetch<NotificationDTO[]>(`/api/v1/notifications`, token)
};

/** Resolve the OIDC bearer token via the shared auth store. */
export function getToken(): string {
  return getTokenFromAuth();
}
