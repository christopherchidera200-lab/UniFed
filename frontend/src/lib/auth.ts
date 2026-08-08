/** OIDC password-grant auth for the UniFed web client.
 *  Talks to POST /api/v1/auth/login -> { access_token, refresh_token }.
 *  Tokens are kept in sessionStorage (cleared on tab close) — acceptable for
 *  the MVP; swap for httpOnly cookies + refresh rotation in production. */

const BASE = process.env.NEXT_PUBLIC_API_BASE ?? "https://api.unifed.ng";
const ACCESS_KEY = "unifed_access";
const REFRESH_KEY = "unifed_refresh";

function store(): Storage | null {
  if (typeof window === "undefined") return null;
  return window.sessionStorage;
}

export interface LoginResult {
  access_token: string;
  refresh_token: string;
  expires_in?: number;
}

export async function login(
  email: string,
  password: string,
  uniSlug: string
): Promise<LoginResult> {
  const res = await fetch(`${BASE}/api/v1/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ email, password, uni_slug: uniSlug })
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body?.reason ?? body?.error ?? `Login failed (${res.status})`);
  }
  const data = (await res.json()) as LoginResult;
  store()?.setItem(ACCESS_KEY, data.access_token);
  store()?.setItem(REFRESH_KEY, data.refresh_token);
  return data;
}

export function getToken(): string {
  return store()?.getItem(ACCESS_KEY) ?? "";
}

export function getRefreshToken(): string {
  return store()?.getItem(REFRESH_KEY) ?? "";
}

export function isAuthed(): boolean {
  return Boolean(getToken());
}

export function logout(): void {
  store()?.removeItem(ACCESS_KEY);
  store()?.removeItem(REFRESH_KEY);
}
