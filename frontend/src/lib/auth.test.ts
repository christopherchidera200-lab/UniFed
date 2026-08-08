import { describe, it, expect, vi, beforeEach } from "vitest";
import { login, getToken, isAuthed, logout } from "@/lib/auth";

// Mock window.sessionStorage (jsdom-free, node env). The app uses
// `window.sessionStorage` (browser). The store() helper guards on typeof window.
const store: Record<string, string> = {};
const ls = {
  getItem: (k: string) => (k in store ? store[k] : null),
  setItem: (k: string, v: string) => {
    store[k] = v;
  },
  removeItem: (k: string) => {
    delete store[k];
  }
};
vi.stubGlobal("window", { sessionStorage: ls } as any);

describe("auth.login", () => {
  beforeEach(() => {
    for (const k of Object.keys(store)) delete store[k];
    vi.restoreAllMocks();
  });

  it("POSTs to /api/v1/auth/login and stores the access token", async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ access_token: "AT-123", refresh_token: "RT-456", expires_in: 900 })
    });
    vi.stubGlobal("fetch", fetchMock);

    const res = await login("a@adun.edu.ng", "pw", "adun");

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, opts] = fetchMock.mock.calls[0];
    expect(url).toContain("/api/v1/auth/login");
    expect(JSON.parse(opts.body)).toEqual({
      email: "a@adun.edu.ng",
      password: "pw",
      uni_slug: "adun"
    });
    expect(res.access_token).toBe("AT-123");
    expect(getToken()).toBe("AT-123");
    expect(isAuthed()).toBe(true);
  });

  it("throws on a non-OK response with the backend reason", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: false, status: 401, json: async () => ({ reason: "bad_creds" }) })
    );
    await expect(login("a@adun.edu.ng", "wrong", "adun")).rejects.toThrow("bad_creds");
    expect(isAuthed()).toBe(false);
  });

  it("logout clears the stored tokens", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ access_token: "AT", refresh_token: "RT" })
      })
    );
    await login("a@adun.edu.ng", "pw", "adun");
    expect(isAuthed()).toBe(true);
    logout();
    expect(isAuthed()).toBe(false);
    expect(getToken()).toBe("");
  });
});
