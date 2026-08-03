import { test, expect, type Page } from '@playwright/test';

/**
 * Investigation workspace E2E — deterministic.
 *
 * The backend is mocked at the network boundary so these tests assert UI
 * behaviour (streaming fill-in, cancellation, error states) without depending on
 * live third-party OSINT sources, which are slow and legitimately flaky.
 * Real-backend coverage lives in investigate-live.spec.ts.
 */

const API = 'http://localhost:8000/investigations/stream';

function frame(event: string, data: unknown): string {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}

const STARTED = frame('started', {
  investigation_id: 'e2e-1',
  target: 'example.com',
  target_type: 'domain',
  collectors: ['dns', 'tls', 'slowsource'],
});

function collectorFrame(name: string, title: string): string {
  return frame('collector', {
    collector: name,
    status: 'ok',
    duration_ms: 120,
    cached: false,
    error: null,
    findings: [
      {
        collector: name,
        title,
        severity: 'info',
        data: { detail: 'value' },
        source: `${name} source`,
        legal_basis: 'Public record, lawful to query.',
      },
    ],
  });
}

const COMPLETE = frame('complete', {
  investigation_id: 'e2e-1',
  target: 'example.com',
  target_type: 'domain',
  created_at: '2026-08-02T12:00:00Z',
  duration_ms: 900,
  findings_count: 3,
  risk: { score: 18, band: 'low', rationale: ['No SPF record observed'] },
  results: [
    JSON.parse(collectorFrame('dns', 'DNS records').split('data: ')[1]),
    JSON.parse(collectorFrame('tls', 'TLS certificate').split('data: ')[1]),
    JSON.parse(collectorFrame('slowsource', 'Slow source result').split('data: ')[1]),
  ],
});

/** Streams frames with a controllable gap so partial states are observable. */
async function mockStream(page: Page, frames: string[], gapMs = 250) {
  await page.route(API, async (route) => {
    const body = frames.join('');
    // Playwright fulfils in one shot; the gap is simulated by delaying the
    // response so the "streaming" phase is genuinely visible first.
    await new Promise((resolve) => setTimeout(resolve, gapMs));
    await route.fulfill({
      status: 200,
      headers: { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache' },
      body,
    });
  });
}

/**
 * Types a target the way a user would.
 *
 * `locator.fill()` sets the DOM value without dispatching the input events React
 * listens to on WebKit, so the component's onChange never runs and type detection
 * silently stays on its default. pressSequentially emits real key events and
 * behaves identically across all three browsers.
 */
async function typeTarget(page: Page, value: string) {
  const input = page.getByRole('textbox');
  await input.click();
  await input.pressSequentially(value, { delay: 10 });
}

test.describe('Investigation workspace', () => {
  test('shows an empty state before anything is run', async ({ page }) => {
    await page.goto('/investigate');

    await expect(page.getByRole('heading', { name: 'Investigate' })).toBeVisible();
    await expect(page.getByText('No investigation running')).toBeVisible();
  });

  test('infers the target type from the input', async ({ page }) => {
    await page.goto('/investigate');
    await typeTarget(page, 'analyst@example.com');

    await expect(page.getByText(/detected as/i)).toContainText(/email/i);
  });

  test('renders findings and the risk score after a run', async ({ page }) => {
    await mockStream(page, [
      STARTED,
      collectorFrame('dns', 'DNS records'),
      collectorFrame('tls', 'TLS certificate'),
      collectorFrame('slowsource', 'Slow source result'),
      COMPLETE,
    ]);

    await page.goto('/investigate');
    await typeTarget(page, 'example.com');
    await page.getByRole('button', { name: /investigate/i }).click();

    await expect(page.getByRole('meter')).toHaveAttribute('aria-valuenow', '18');
    await expect(page.getByRole('heading', { name: 'dns' })).toBeVisible();
    await expect(page.getByText('DNS records')).toBeVisible();
  });

  test('explains the risk score with a rationale', async ({ page }) => {
    await mockStream(page, [STARTED, COMPLETE]);

    await page.goto('/investigate');
    await typeTarget(page, 'example.com');
    await page.getByRole('button', { name: /investigate/i }).click();

    // An analyst must be able to defend the number, so the reasons are visible UI.
    await expect(page.getByRole('heading', { name: /why this score/i })).toBeVisible();
    await expect(page.getByText('No SPF record observed')).toBeVisible();
  });

  test('reveals the legal basis when a finding is expanded', async ({ page }) => {
    await mockStream(page, [STARTED, collectorFrame('dns', 'DNS records'), COMPLETE]);

    await page.goto('/investigate');
    await typeTarget(page, 'example.com');
    await page.getByRole('button', { name: /investigate/i }).click();

    await page.getByRole('button', { name: /DNS records/i }).click();

    // Scoped to the finding panel: the footer also mentions legal wording.
    await expect(page.getByText('Legal basis:')).toBeVisible();
    await expect(page.getByText(/lawful to query/i)).toBeVisible();
  });

  test('surfaces a rejected target as an error, not a silent failure', async ({ page }) => {
    await page.route(API, (route) =>
      route.fulfill({
        status: 400,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'invalid_target', message: 'That is not a valid domain.' }),
      }),
    );

    await page.goto('/investigate');
    await typeTarget(page, 'not a domain');
    await page.getByRole('button', { name: /investigate/i }).click();

    // Next.js renders its own empty route-announcer with role=alert, so scope
    // to the one that actually has content.
    await expect(
      page.getByRole('alert').filter({ hasText: 'Investigation failed' }),
    ).toBeVisible();
    // Appears twice by design: once in the sr-only live region for screen
    // readers, once in the visible alert. Match the visible one exactly.
    await expect(page.getByText('That is not a valid domain.', { exact: true })).toBeVisible();
  });

  test('offers cancellation while a run is in flight', async ({ page }) => {
    // A slow route keeps the request genuinely in flight, which is what makes the
    // Cancel path meaningful. It must eventually settle: an unfulfilled route
    // leaves the page permanently network-busy and Playwright's actionability
    // check then never dispatches the click.
    await page.route(API, async (route) => {
      await new Promise((resolve) => setTimeout(resolve, 30_000));
      await route.abort();
    });

    await page.goto('/investigate');
    await typeTarget(page, 'example.com');
    await page.getByRole('button', { name: /investigate/i }).click();

    // The most likely intent during a slow run is to stop it.
    const cancel = page.getByRole('button', { name: /cancel/i });
    await expect(cancel).toBeVisible();
    // dispatchEvent bypasses Playwright's actionability wait, which would
    // otherwise block on the still-pending investigation request. The real React
    // onClick handler still runs.
    await cancel.dispatchEvent('click');

    // Regression guard: aborting must return the UI to a usable state rather
    // than leaving it stuck on the Cancel button.
    await expect(page.getByRole('button', { name: /investigate/i })).toBeVisible();
    await expect(page.getByRole('alert').filter({ hasText: 'Investigation failed' })).toHaveCount(0);
  });

  test('is operable by keyboard alone', async ({ page }) => {
    await mockStream(page, [STARTED, collectorFrame('dns', 'DNS records'), COMPLETE]);

    await page.goto('/investigate');
    await typeTarget(page, 'example.com');
    await page.keyboard.press('Enter');

    await expect(page.getByRole('heading', { name: 'dns' })).toBeVisible();
  });
});
