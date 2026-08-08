import { test, expect } from "@playwright/test";

// Real-browser E2E with the backend API stubbed via page.route.
// Flow: open /login -> submit -> token stored -> /catalog fetches + renders.

test.beforeEach(async ({ page }) => {
  // Stub the OIDC password-grant login.
  await page.route("**/api/v1/auth/login", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ access_token: "test-access", refresh_token: "test-refresh", expires_in: 900 })
    })
  );
  // Stub catalogue + library reads. Trailing '*' absorbs the empty '?' query
  // string Next appends (e.g. /catalog/courses?).
  await page.route("**/api/v1/catalog/courses*", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([
        { id: "c1", code: "CSC301", title: "Algorithms", credit_units: 3, level: 300, semester: 1, programme_id: "p1", prerequisites: [] },
        { id: "c2", code: "CSC305", title: "Operating Systems", credit_units: 3, level: 300, semester: 2, programme_id: "p1", prerequisites: [] }
      ])
    })
  );
  await page.route("**/api/v1/library/resources*", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([
        { id: "r1", title: "Introduction to Algorithms", author: "Cormen", type: "book", available: true }
      ])
    })
  );
});

test("logs in and browses the course catalogue", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[type="email"]', "student@adun.edu.ng");
  await page.fill('input[type="password"]', "Passw0rd!");
  await page.click('button[type="submit"]');

  // Redirected to the discover hub after login.
  await expect(page).toHaveURL(/\/discover/);

  // Token stored in sessionStorage.
  const token = await page.evaluate(() => window.sessionStorage.getItem("unifed_access"));
  expect(token).toBe("test-access");

  // Catalogue renders fetched courses.
  await page.goto("/catalog");
  await expect(page.getByText("CSC301")).toBeVisible();
  await expect(page.getByText("Algorithms")).toBeVisible();
});

test("authed library page renders resources", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[type="email"]', "student@adun.edu.ng");
  await page.fill('input[type="password"]', "Passw0rd!");
  await page.click('button[type="submit"]');
  await page.goto("/library");
  await expect(page.getByText("Introduction to Algorithms")).toBeVisible();
  await expect(page.getByText("Available")).toBeVisible();
});
