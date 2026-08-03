import { test, expect } from '@playwright/test';

/**
 * Live end-to-end proof: a real organization investigation, streamed from the
 * actual backend on :8000 (no mocking). Confirms the full stack — UI -> SSE
 * client -> FastAPI -> OrganizationCollector (RDAP + DNS/ASN) -> scored response
 * — works for the organization target type in production-shaped conditions.
 *
 * Requires the backend running: `uvicorn app.main:app --port 8000`.
 */
test('live organization investigation returns a real ownership graph', async ({ page }) => {
  await page.goto('/investigate');
  await page.getByRole('textbox').click();
  await page.getByRole('textbox').pressSequentially('google.com', { delay: 10 });

  // Select the organization target type via the override radiogroup.
  await page.getByRole('radio', { name: 'organization' }).click();
  await page.getByRole('button', { name: /investigate/i }).click();

  // Real RDAP/DNS-derived findings must arrive and render.
  await expect(page.getByText('Organization profile')).toBeVisible({ timeout: 30000 });
  await expect(page.getByText('Originating Autonomous System')).toBeVisible({ timeout: 30000 });
  await expect(page.getByText('Accredited registrar')).toBeVisible({ timeout: 30000 });
  // The risk meter should settle to a real score.
  await expect(page.getByRole('meter')).toBeVisible();
});
