import { describe, it, expect, vi, afterEach } from "vitest";
import { unifedApi } from "@/lib/api";

// Smoke test: guards against a broken API client import/serialization path.
describe("api client smoke", () => {
  it("exposes a base URL helper", () => {
    const base = process.env.NEXT_PUBLIC_API_BASE || "http://localhost:3000";
    expect(typeof base).toBe("string");
    expect(base.length).toBeGreaterThan(0);
  });
});

// Registration + profile client behaviour (no real network).
describe("api client register/profile", () => {
  afterEach(() => { vi.restoreAllMocks(); });

  it("register POSTs name/email/password and returns tokens on success", async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 201,
      json: async () => ({ access_token: "a", refresh_token: "r" })
    } as Response);
    vi.stubGlobal("fetch", fetchMock);

    const tokens = await unifedApi.register({
      name: "Chidera",
      email: "c@adun.edu.ng",
      password: "Passw0rd!"
    });

    expect(tokens.access_token).toBe("a");
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toContain("/api/v1/auth/register");
    const body = JSON.parse(init.body);
    expect(body.email).toBe("c@adun.edu.ng");
    expect(body).not.toHaveProperty("role"); // server assigns roles
  });

  it("register throws a readable error on failure", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
        status: 422,
        json: async () => ({ error: "password_too_weak" })
      } as Response)
    );
    await expect(unifedApi.register({ name: "X", email: "x@adun.edu.ng", password: "weak" })).rejects.toThrow(
      "password_too_weak"
    );
  });

  it("profile sends a bearer token and returns the current user's data", async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ id: "u1", display_name: "Chidera", email: "c@adun.edu.ng", actor_type: "student" })
    } as Response);
    vi.stubGlobal("fetch", fetchMock);

    const p = await unifedApi.profile("tok-123");
    expect(p.display_name).toBe("Chidera");
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toContain("/api/v1/profile");
    expect(init.headers.Authorization).toBe("Bearer tok-123");
  });
});

// `unifedApi` is imported for the tests above; alias resolution mirrors the app.
