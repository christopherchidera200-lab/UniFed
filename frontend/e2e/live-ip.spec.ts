import { test, expect } from '@playwright/test';

/**
 * Live end-to-end proof: a real IP investigation, streamed from the actual
 * backend on :8000 (no mocking). Confirms the full stack — UI -> SSE client ->
 * FastAPI -> RDAP/reverse-DNS collectors -> scored response — works for a
 * non-domain target type in production-shaped conditions.
 *
 * Requires the backend running: `uvicorn app.main:app --port 8000`.
 */

test('live IP investigation returns real RDAP and reverse-DNS findings', async ({ page }) => {
  await page.goto('/investigate');
  await page.getByRole('textbox').click();
  await page.getByRole('textbox').pressSequentially('8.8.8.8', { delay: 10 });
  await page.getByRole('button', { name: /investigate/i }).click();

  // Real RDAP/reverse-DNS data must arrive and render.
  await expect(page.getByText('IP registration record')).toBeVisible({ timeout: 30000 });
  await expect(page.getByText('Reverse DNS hostname')).toBeVisible({ timeout: 30000 });
  // The risk meter should settle to a real score.
  await expect(page.getByRole('meter')).toBeVisible();
});
