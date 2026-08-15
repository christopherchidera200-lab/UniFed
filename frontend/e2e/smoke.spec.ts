import { test, expect } from "@playwright/test";

// Real-browser E2E with the backend API stubbed via page.route.
// Flow: open /login -> submit -> token stored -> protected pages fetch + render.

test.beforeEach(async ({ page }) => {
  // Stub the OIDC password-grant login.
  await page.route("**/api/v1/auth/login", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ access_token: "test-access", refresh_token: "test-refresh", expires_in: 900 })
    })
  );
  // Stub the current user's profile (real name, not hardcoded).
  await page.route("**/api/v1/profile", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        id: "u1", display_name: "Christopher", email: "student@adun.edu.ng",
        actor_type: "student", bio: null, skills: [], portfolio: [], social_links: {}, creator: false
      })
    })
  );
  // Stub the current user's academic identity (resolved server-side, no hardcoded id).
  await page.route("**/api/v1/academic/me", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ id: "s1", university_id: "u1", matric_no: "ADUN/ENG/CSC/21/001" })
    })
  );
  // Stub academic records + summary for the resolved student identity.
  await page.route("**/api/v1/academic/u1/students/s1/records*", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([
        { course_code: "CSC301", course_title: "Algorithms", credit_units: 3, score: 85, grade_letter: "A", grade_point: 4.0, semester: 1 }
      ])
    })
  );
  await page.route("**/api/v1/academic/u1/students/s1/summary*", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ matric_no: "ADUN/ENG/CSC/21/001", cgpa: 4.2, total_credits: 30, class_of_degree: "First Class" })
    })
  );
  // Stub post creation.
  await page.route("**/api/v1/feed/posts", (route) =>
    route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({ id: "p1", body: "Hello federation", visibility: "university" })
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

test("home dashboard greets the authenticated user by real name", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[type="email"]', "student@adun.edu.ng");
  await page.fill('input[type="password"]', "Passw0rd!");
  await page.click('button[type="submit"]');
  await page.goto("/");
  // Real name from /api/v1/profile (the <h1> greeting), not a hardcoded "ADUN Student".
  await expect(page.getByRole("heading", { name: "Christopher" })).toBeVisible();
});

test("create page submits a valid post", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[type="email"]', "student@adun.edu.ng");
  await page.fill('input[type="password"]', "Passw0rd!");
  await page.click('button[type="submit"]');
  await page.goto("/create");
  await page.fill("textarea", "Hello federation");
  await page.getByRole("button", { name: "Post" }).click();
  await expect(page.getByText("Posted to your community.")).toBeVisible();
});

test("academic records uses the authenticated student identity", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[type="email"]', "student@adun.edu.ng");
  await page.fill('input[type="password"]', "Passw0rd!");
  await page.click('button[type="submit"]');
  await page.goto("/academic/records");
  // Matric from /api/v1/academic/me (no hardcoded id).
  await expect(page.getByText("ADUN/ENG/CSC/21/001")).toBeVisible();
  // A published grade record renders.
  await expect(page.getByText("CSC301")).toBeVisible();
  await expect(page.getByText("Algorithms")).toBeVisible();
});
