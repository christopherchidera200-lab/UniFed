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
  // Phase 3 — campus (public), assignments (token), research (public), admin (token).
  await page.route("**/api/v1/campus/places*", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([
        { id: "p1", campus_id: "c1", university_id: "u1", name: "Main Library", kind: "library",
          description: "Central collection", lat: 5.1, lng: 7.2, accessibility_level: "full", metadata: {} }
      ])
    })
  );
  await page.route("**/api/v1/assignments*", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([
        { id: "a1", course_offering_id: "co1", lecturer_id: "l1", title: "Essay 1",
          description: "Write about federation", instructions: null, max_score: 100,
          due_at: "2026-09-30T23:59:00Z", published: true, my_submission: null }
      ])
    })
  );
  await page.route("**/api/v1/research/profiles*", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([
        { id: "rp1", user_id: "u1", title: "Dr. Chidera", bio: null, orcid: null,
          research_fields: ["ML", "Security"], citations_count: 42 }
      ])
    })
  );
  await page.route("**/api/v1/research/groups*", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([
        { id: "g1", name: "FedML Lab", description: "Federated learning research", lead_id: "u1" }
      ])
    })
  );
  await page.route("**/api/v1/admin/stats*", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ users: 3, roles: 2, research_groups: 1, campus_places: 5, assignments: 4 })
    })
  );
  await page.route("**/api/v1/admin/users*", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        users: [
          { id: "u1", email: "student@adun.edu.ng", username: null, display_name: "Christopher",
            actor_type: "student", status: "active", roles: ["student"] }
        ],
        total: 1
      })
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

test("smart campus page renders places", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[type="email"]', "student@adun.edu.ng");
  await page.fill('input[type="password"]', "Passw0rd!");
  await page.click('button[type="submit"]');
  await page.goto("/campus");
  await expect(page.getByText("Smart Campus")).toBeVisible();
  await expect(page.getByText("Main Library")).toBeVisible();
});

test("assignments page renders the student view", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[type="email"]', "student@adun.edu.ng");
  await page.fill('input[type="password"]', "Passw0rd!");
  await page.click('button[type="submit"]');
  await page.goto("/assignments");
  await expect(page.getByText("Assignments")).toBeVisible();
  await expect(page.getByText("Essay 1")).toBeVisible();
});

test("research hub renders profiles and groups", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[type="email"]', "student@adun.edu.ng");
  await page.fill('input[type="password"]', "Passw0rd!");
  await page.click('button[type="submit"]');
  await page.goto("/research");
  await expect(page.getByText("Research Hub")).toBeVisible();
  await expect(page.getByText("Dr. Chidera")).toBeVisible();
  await expect(page.getByText("FedML Lab")).toBeVisible();
});

test("administration page renders stats and users", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[type="email"]', "student@adun.edu.ng");
  await page.fill('input[type="password"]', "Passw0rd!");
  await page.click('button[type="submit"]');
  await page.goto("/admin");
  await expect(page.getByRole("heading", { name: "Administration" })).toBeVisible();
  await expect(page.getByText("Christopher")).toBeVisible();
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
