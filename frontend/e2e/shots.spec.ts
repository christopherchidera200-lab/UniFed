import { test } from "@playwright/test";

const OUT = "screenshots";

test.beforeEach(async ({ page }) => {
  await page.route("**/api/v1/auth/login*", (r) =>
    r.fulfill({ status: 200, contentType: "application/json",
      body: JSON.stringify({ access_token: "t", refresh_token: "r", expires_in: 900 }) }));
  await page.route("**/api/v1/catalog/courses*", (r) =>
    r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify([
      { id: "c1", code: "CSC301", title: "Algorithms", credit_units: 3, level: 300, semester: 1, programme_id: "p1", prerequisites: [] },
      { id: "c2", code: "CSC305", title: "Operating Systems", credit_units: 3, level: 300, semester: 2, programme_id: "p1", prerequisites: [] },
      { id: "c3", code: "CSC401", title: "Compiler Construction", credit_units: 2, level: 400, semester: 1, programme_id: "p1", prerequisites: [] }
    ]) }));
  await page.route("**/api/v1/career/opportunities*", (r) =>
    r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify([
      { id: "o1", title: "Backend Engineering Intern", employer: "Naija Tech", employment_type: "internship", location: "Lagos", salary_range: "₦150k/mo" },
      { id: "o2", title: "Graduate Trainee, Data", employer: "FedGov", employment_type: "full_time", location: "Abuja", salary_range: "₦250k/mo" }
    ]) }));
  await page.route("**/api/v1/calendar/events*", (r) =>
    r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify([
      { id: "e1", title: "Matriculation 2026", type: "matriculation", event_start: "2026-09-01T10:00:00Z", event_end: null, faculty_id: null, department_id: null },
      { id: "e2", title: "CSC301 Exam", type: "exam", event_start: "2026-09-20T09:00:00Z", event_end: null, faculty_id: null, department_id: null },
      { id: "e3", title: "Tech Week", type: "general", event_start: "2026-10-05T09:00:00Z", event_end: null, faculty_id: null, department_id: null }
    ]) }));
  await page.route("**/api/v1/library/resources*", (r) =>
    r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify([
      { id: "r1", title: "Introduction to Algorithms", author: "Cormen", type: "book", available: true },
      { id: "r2", title: "Structure and Interpretation of Computer Programs", author: "Abelson", type: "book", available: false }
    ]) }));
  await page.route("**/api/v1/notifications*", (r) =>
    r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify([
      { id: "n1", category: "academic", title: "New grade posted: CSC301", body: "You scored 82 in Algorithms.", created_at: "2026-08-08T12:00:00Z" },
      { id: "n2", category: "finance", title: "Fee reminder", body: "Session fees due Sept 1.", created_at: "2026-08-07T09:00:00Z" }
    ]) }));
  await page.route("**/api/v1/academic/students/*/records*", (r) =>
    r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify([
      { id: "g1", course_code: "CSC301", course_title: "Algorithms", score: 82, grade_letter: "A", credit_units: 3, is_published: true }
    ]) }));
  await page.route("**/api/v1/academic/students/*/summary*", (r) =>
    r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify({
      student_id: "s1", cgpa: 4.2, total_credit_units: 21, level: 300, matric_no: "2021/12345", published_grades: 7
    }) }));
});

async function shot(page: any, path: string, file: string, dark = false) {
  await page.goto(path);
  if (dark) {
    await page.evaluate(() => {
      localStorage.setItem("unifed-theme", "dark");
      document.documentElement.classList.add("dark");
    });
    await page.reload();
  }
  await page.waitForTimeout(1200);
  await page.screenshot({ path: `${OUT}/${file}`, fullPage: true });
}

test("capture all pages (light + key dark)", async ({ page }) => {
  await page.goto("/login");
  await page.fill('input[type="email"]', "student@adun.edu.ng");
  await page.fill('input[type="password"]', "Passw0rd!");
  await page.click('button[type="submit"]');
  await page.waitForTimeout(800);

  await shot(page, "/", "01-home.png");
  await shot(page, "/discover", "02-discover.png");
  await shot(page, "/catalog", "03-catalog.png");
  await shot(page, "/career", "04-career.png");
  await shot(page, "/events", "05-events.png");
  await shot(page, "/library", "06-library.png");
  await shot(page, "/notifications", "07-notifications.png");
  await shot(page, "/academic/records", "08-records.png");
  await shot(page, "/connect", "09-connect.png");
  await shot(page, "/create", "10-create.png");
  await shot(page, "/profile", "11-profile.png");

  // Dark mode hero shots
  await shot(page, "/", "01b-home-dark.png", true);
  await shot(page, "/catalog", "03b-catalog-dark.png", true);

  // Login (logged out)
  await page.evaluate(() => window.sessionStorage.clear());
  await page.goto("/login");
  await page.waitForTimeout(800);
  await page.screenshot({ path: `${OUT}/00-login.png`, fullPage: true });
});

