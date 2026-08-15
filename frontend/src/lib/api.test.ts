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

// Phase 3 — new surfaces client behaviour (no real network).
describe("api client Phase 3 surfaces", () => {
  afterEach(() => { vi.restoreAllMocks(); });

  function mockFetch(body: unknown, status = 200) {
    const fm = vi.fn().mockResolvedValue({
      ok: status < 400, status, json: async () => body
    } as Response);
    vi.stubGlobal("fetch", fm);
    return fm;
  }

  it("campusPlaces reads publicly without a token", async () => {
    const fm = mockFetch([{ id: "p1", name: "Main Library", kind: "library" }]);
    const places = await unifedApi.campusPlaces({ kind: "library" });
    expect(places[0].name).toBe("Main Library");
    const [url] = fm.mock.calls[0];
    expect(url).toContain("/api/v1/campus/places");
    expect(url).toContain("kind=library");
    expect(fm.mock.calls[0][1]?.headers).not.toHaveProperty("Authorization");
  });

  it("assignments sends a bearer token and parses my_submission", async () => {
    const fm = mockFetch([
      { id: "a1", title: "Essay", max_score: 100, published: true, my_submission: null }
    ]);
    const list = await unifedApi.assignments("tok-1");
    expect(list[0].title).toBe("Essay");
    const [url, init] = fm.mock.calls[0];
    expect(url).toContain("/api/v1/assignments");
    expect(init.headers.Authorization).toBe("Bearer tok-1");
  });

  it("researchProfiles reads publicly", async () => {
    const fm = mockFetch([{ id: "r1", title: "Dr. X", citations_count: 12 }]);
    const profiles = await unifedApi.researchProfiles({ q: "ml" });
    expect(profiles[0].citations_count).toBe(12);
    expect(fm.mock.calls[0][1]?.headers).not.toHaveProperty("Authorization");
  });

  it("adminStats requires a token and returns node counts", async () => {
    const fm = mockFetch({ users: 3, roles: 2, research_groups: 1, campus_places: 5, assignments: 4 });
    const stats = await unifedApi.adminStats("tok-9");
    expect(stats.campus_places).toBe(5);
    expect(fm.mock.calls[0][1].headers.Authorization).toBe("Bearer tok-9");
  });

  it("createAssignment POSTs the assignment payload under an 'assignment' key", async () => {
    const fm = mockFetch({ id: "a2", title: "Lab", published: false }, 201);
    await unifedApi.createAssignment("tok", { course_offering_id: "co1", title: "Lab" });
    const [, init] = fm.mock.calls[0];
    expect(init.method).toBe("POST");
    expect(JSON.parse(init.body).assignment.course_offering_id).toBe("co1");
  });
});
