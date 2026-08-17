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

/** Persist tokens into the existing session store (used after registration auto-login). */
export function storeTokens(tokens: { access_token: string; refresh_token: string; expires_in?: number }): void {
  store()?.setItem(ACCESS_KEY, tokens.access_token);
  store()?.setItem(REFRESH_KEY, tokens.refresh_token);
  if (tokens.expires_in) {
    const exp = Date.now() + tokens.expires_in * 1000;
    store()?.setItem("unifed_expires_at", String(exp));
  }
}

/** When the access token is expected to expire (ms epoch), or null if unknown. */
export function getExpiresAt(): number | null {
  const v = store()?.getItem("unifed_expires_at");
  return v ? Number(v) : null;
}

/**
 * Refresh the access token using the stored refresh token.
 * Returns true on success (new tokens stored). On failure the session is
 * cleared — the caller should route the user to /login.
 *
 * NOTE: endpoint shape depends on the backend; adjust the path/body if the
 * Rails app exposes a different refresh route.
 */
export async function refreshSession(): Promise<boolean> {
  const rt = getRefreshToken();
  if (!rt) { logout(); return false; }
  try {
    const res = await fetch(`${BASE}/api/v1/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({ refresh_token: rt })
    });
    if (!res.ok) { logout(); return false; }
    const data = (await res.json()) as { access_token: string; refresh_token?: string; expires_in?: number };
    storeTokens({
      access_token: data.access_token,
      refresh_token: data.refresh_token ?? rt,
      expires_in: data.expires_in
    });
    return true;
  } catch {
    logout();
    return false;
  }
}
