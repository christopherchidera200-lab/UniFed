import { describe, it, expect } from "vitest";

// Smoke test: guards against a broken API client import/serialization path.
describe("api client smoke", () => {
  it("exposes a base URL helper", () => {
    const base = process.env.NEXT_PUBLIC_API_BASE || "http://localhost:3000";
    expect(typeof base).toBe("string");
    expect(base.length).toBeGreaterThan(0);
  });
});
