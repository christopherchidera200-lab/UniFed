import { defineConfig, devices } from "@playwright/test";

// E2E against a MOCKED backend (page.route intercepts API calls). Proves the
// real browser flow: login -> token stored -> authed pages fetch + render.
// No live backend required (true backend E2E lands with cloud provisioning).
//
// The dev server is started separately (npm run dev) and assumed running at
// E2E_BASE_URL (default http://localhost:3000). webServer is intentionally
// NOT auto-managed here to avoid port clashes in local runs; CI's e2e job
// starts its own server before `npm run e2e`.
export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  retries: 0,
  use: {
    baseURL: process.env.E2E_BASE_URL ?? "http://localhost:3000",
    headless: true
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }]
});
