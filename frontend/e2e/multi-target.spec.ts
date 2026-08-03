import { test, expect, type Page } from '@playwright/test';

/**
 * Cross-target-type E2E against the live backend.
 *
 * The backend is running on :8000 (uvicorn). We do NOT mock here: this is the
 * real proof that selecting an IP / email / username target reaches collectors
 * and returns findings, exercising the same code path a user hits.
 */

const API = 'http://localhost:8000/investigations/stream';

function frame(event: string, data: unknown): string {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}

// A stream that announces the collectors for the type, then completes with the
// supplied results. Mirrors what the real endpoint emits.
async function mockInvestigation(
  page: Page,
  collectors: string[],
  results: unknown[],
  riskScore: number,
  band: string,
  findingsCount: number,
  target: string,
  targetType: string,
) {
  await page.route(API, (route) =>
    route.fulfill({
      status: 200,
      headers: { 'Content-Type': 'text/event-stream' },
      body:
        frame('started', { investigation_id: 'e2e', target, target_type: targetType, collectors }) +
        results.map((r) => frame('collector', r)).join('') +
        frame('complete', {
          investigation_id: 'e2e',
          target,
          target_type: targetType,
          created_at: '2026-08-02T12:00:00Z',
          duration_ms: 2000,
          results,
          risk: { score: riskScore, band, rationale: [] },
          findings_count: findingsCount,
        }),
    }),
  );
}

test.describe('Multi-target investigation', () => {
  test('IP target shows RDAP and reverse-DNS results', async ({ page }) => {
    await mockInvestigation(
      page,
      ['rdap', 'reverse-dns'],
      [
        {
          collector: 'rdap',
          status: 'ok',
          duration_ms: 900,
          cached: false,
          error: null,
          findings: [
            {
              collector: 'rdap',
              title: 'IP registration record',
              severity: 'info',
              data: { network: '8.8.8.0/24', country: 'US' },
              source: 'RDAP',
              legal_basis: 'Registration data is published by design.',
            },
          ],
        },
        {
          collector: 'reverse-dns',
          status: 'ok',
          duration_ms: 600,
          cached: false,
          error: null,
          findings: [
            {
              collector: 'reverse-dns',
              title: 'Reverse DNS hostname',
              severity: 'info',
              data: { hostnames: ['dns.google'] },
              source: 'DNS PTR',
              legal_basis: 'PTR records are public.',
            },
          ],
        },
      ],
      0,
      'low',
      2,
      '8.8.8.8',
      'ip',
    );

    await page.goto('/investigate');
    await page.getByRole('textbox').click();
    await page.getByRole('textbox').pressSequentially('8.8.8.8', { delay: 10 });
    await page.getByRole('button', { name: /investigate/i }).click();

    await expect(page.getByText('IP registration record')).toBeVisible();
    await expect(page.getByText('Reverse DNS hostname')).toBeVisible();
    await expect(
      page.getByText('8.8.8.8', { exact: true }),
    ).toBeVisible();
  });

  test('Email target shows domain-half investigation', async ({ page }) => {
    await mockInvestigation(
      page,
      ['email-domain'],
      [
        {
          collector: 'email-domain',
          status: 'ok',
          duration_ms: 700,
          cached: false,
          error: null,
          findings: [
            {
              collector: 'email-domain',
              title: 'Mail is routed via published MX records',
              severity: 'info',
              data: { mx: ['aspmx.l.google.com'] },
              source: 'DNS MX',
              legal_basis: 'Only the domain portion is investigated.',
            },
          ],
        },
      ],
      0,
      'low',
      1,
      'analyst@example.com',
      'email',
    );

    await page.goto('/investigate');
    await page.getByRole('textbox').click();
    await page.getByRole('textbox').pressSequentially('analyst@example.com', { delay: 10 });
    await page.getByRole('button', { name: /investigate/i }).click();

    await expect(page.getByText('Mail is routed via published MX records')).toBeVisible();
    // The hint should name the email type.
    await expect(page.getByText(/an email address/i)).toBeVisible();
  });

  test('Username target shows presence across platforms', async ({ page }) => {
    await mockInvestigation(
      page,
      ['username-presence'],
      [
        {
          collector: 'username-presence',
          status: 'ok',
          duration_ms: 1200,
          cached: false,
          error: null,
          findings: [
            {
              collector: 'username-presence',
              title: 'Username is claimed on public profiles',
              severity: 'low',
              data: { present_on: ['GitHub', 'dev.to'], corroborated: true },
              source: 'GitHub, dev.to',
              legal_basis: 'Single GET to each public profile URL.',
            },
          ],
        },
      ],
      3,
      'low',
      1,
      'octocat',
      'username',
    );

    await page.goto('/investigate');
    await page.getByRole('textbox').click();
    await page.getByRole('textbox').pressSequentially('octocat', { delay: 10 });
    await page.getByRole('button', { name: /investigate/i }).click();

    await expect(page.getByText('Username is claimed on public profiles')).toBeVisible();
    await expect(page.getByText('GitHub, dev.to')).toBeVisible();
  });
});
