import { expect, test } from '@playwright/test';

/**
 * Phase 0 e2e coverage: the design system, theming and accessibility scaffolding
 * behave correctly in a real browser. Investigation flows are added in Phase 2.
 */

test.describe('Landing page', () => {
  test('renders the product proposition', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('heading', { level: 1 })).toContainText('Legal OSINT');
  });

  test('exposes exactly one h1 and a correct heading hierarchy', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('h1')).toHaveCount(1);
    await expect(page.locator('h2')).not.toHaveCount(0);
  });

  // WebKit excludes links from sequential Tab order unless the user enables
  // "Press Tab to highlight each item" at the OS level, so the tab-order
  // assertion is Chromium-only. The focus-reveal behaviour below is asserted on
  // every engine, because that is the part our CSS is responsible for.
  test('skip link is the first tab stop', async ({ page, browserName }) => {
    test.skip(browserName === 'webkit', 'WebKit omits links from default Tab order');
    await page.goto('/');
    await page.keyboard.press('Tab');

    await expect(page.getByRole('link', { name: 'Skip to main content' })).toBeFocused();
  });

  test('skip link reveals itself on focus and targets the main landmark', async ({ page }) => {
    await page.goto('/');
    const skipLink = page.getByRole('link', { name: 'Skip to main content' });

    // Off-canvas until focused, so it never intrudes on the visual design.
    await expect(skipLink).not.toBeInViewport();

    await skipLink.focus();
    await expect(skipLink).toBeInViewport();
    await expect(skipLink).toHaveAttribute('href', '#main');
  });

  test('main landmark is present for screen-reader navigation', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('main')).toBeVisible();
  });
});

test.describe('Theming', () => {
  test('honours the OS dark-mode preference on first paint', async ({ browser }) => {
    const context = await browser.newContext({ colorScheme: 'dark' });
    const page = await context.newPage();
    await page.goto('/');

    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
    await context.close();
  });

  test('toggle flips the theme and persists it across a reload', async ({ page }) => {
    await page.goto('/');
    const html = page.locator('html');
    const initial = await html.getAttribute('data-theme');

    await page.getByRole('button', { name: /switch to (light|dark) theme/i }).click();
    const flipped = initial === 'dark' ? 'light' : 'dark';
    await expect(html).toHaveAttribute('data-theme', flipped);

    await page.reload();
    await expect(html).toHaveAttribute('data-theme', flipped);
  });

  test('does not flash the wrong theme before hydration', async ({ browser }) => {
    const context = await browser.newContext({ colorScheme: 'dark' });
    const page = await context.newPage();
    // domcontentloaded fires before React hydrates; the inline script must already
    // have resolved the theme by this point.
    await page.goto('/', { waitUntil: 'domcontentloaded' });

    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
    await context.close();
  });
});

test.describe('Responsive layout', () => {
  test('renders without horizontal overflow on a small viewport', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto('/');

    const overflows = await page.evaluate(
      () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
    );
    expect(overflows).toBe(false);
  });
});
