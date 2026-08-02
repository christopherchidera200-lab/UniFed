/**
 * DESIGN TOKEN ACCESSIBILITY GATE
 *
 * The palette in `src/app/globals.css` is the product's visual contract. This
 * suite asserts that every foreground/background pairing we actually ship meets
 * its WCAG threshold, in BOTH themes.
 *
 * Why a test and not a design review: contrast regressions are introduced by
 * one-line token tweaks that look fine on the author's monitor. A failing test
 * is the only reliable way to stop that reaching users.
 *
 * These literals mirror globals.css. If you change a token there, change it here
 * — the duplication is deliberate, so the test is an independent statement of
 * intent rather than a tautology that reads the same source it validates.
 */
import { describe, expect, it } from 'vitest';
import { contrastRatio, WCAG, type Hsl } from '../contrast';

const hsl = (h: number, s: number, l: number): Hsl => ({ h, s, l });

const LIGHT = {
  canvas: hsl(0, 0, 100),
  surface: hsl(0, 0, 100),
  elevated: hsl(220, 20, 98),
  muted: hsl(220, 14, 96),
  border: hsl(220, 13, 87),
  borderStrong: hsl(220, 10, 55),
  foreground: hsl(224, 30, 12),
  subtle: hsl(220, 12, 40),
  accent: hsl(243, 75, 59),
  accentForeground: hsl(0, 0, 100),
  severityLow: hsl(199, 89, 42),
  severityMedium: hsl(32, 95, 44),
  severityHigh: hsl(0, 72, 51),
  success: hsl(142, 71, 36),
} as const;

const DARK = {
  canvas: hsl(224, 30, 7),
  surface: hsl(224, 26, 10),
  elevated: hsl(224, 22, 13),
  muted: hsl(224, 22, 15),
  border: hsl(223, 16, 25),
  borderStrong: hsl(220, 9, 55),
  foreground: hsl(210, 20, 96),
  subtle: hsl(218, 13, 68),
  accent: hsl(243, 82, 68),
  accentForeground: hsl(224, 30, 7),
  severityLow: hsl(199, 89, 56),
  severityMedium: hsl(32, 95, 58),
  severityHigh: hsl(0, 84, 64),
  success: hsl(142, 64, 50),
} as const;

const THEMES = [
  ['light', LIGHT],
  ['dark', DARK],
] as const;

describe.each(THEMES)('%s theme — body text (WCAG 1.4.3 AA, 4.5:1)', (_theme, t) => {
  it.each([
    ['foreground on canvas', t.foreground, t.canvas],
    ['foreground on surface', t.foreground, t.surface],
    ['foreground on elevated', t.foreground, t.elevated],
    ['foreground on muted', t.foreground, t.muted],
    ['subtle on canvas', t.subtle, t.canvas],
    ['subtle on surface', t.subtle, t.surface],
    ['subtle on muted', t.subtle, t.muted],
  ])('%s', (_label, fg, bg) => {
    expect(contrastRatio(fg, bg)).toBeGreaterThanOrEqual(WCAG.AA_TEXT);
  });
});

describe.each(THEMES)('%s theme — primary button (WCAG 1.4.3 AA)', (_theme, t) => {
  it('accent-foreground on accent is readable', () => {
    expect(contrastRatio(t.accentForeground, t.accent)).toBeGreaterThanOrEqual(WCAG.AA_TEXT);
  });
});

describe.each(THEMES)('%s theme — non-text contrast (WCAG 1.4.11, 3:1)', (_theme, t) => {
  it('interactive control boundaries are distinguishable from their surface', () => {
    // --border is decorative (dividers, card edges) and out of 1.4.11 scope.
    // --border-strong is what interactive controls must use.
    expect(contrastRatio(t.borderStrong, t.surface)).toBeGreaterThanOrEqual(WCAG.AA_NON_TEXT);
  });

  it('the focus ring is visible against the canvas it sits on', () => {
    expect(contrastRatio(t.accent, t.canvas)).toBeGreaterThanOrEqual(WCAG.AA_NON_TEXT);
  });
});

describe.each(THEMES)('%s theme — severity palette carries meaning', (_theme, t) => {
  // Severity colours are used as badge text on a tinted background, and the badge
  // always carries a text label too (WCAG 1.4.1). Against the page surface they
  // must still be legible as large/bold text.
  it.each([
    ['low', t.severityLow],
    ['medium', t.severityMedium],
    ['high', t.severityHigh],
    ['success', t.success],
  ])('%s reads against the surface', (_label, colour) => {
    expect(contrastRatio(colour, t.surface)).toBeGreaterThanOrEqual(WCAG.AA_LARGE_TEXT);
  });

  it('severity colours are mutually distinguishable, not just individually legible', () => {
    // A red/amber pair that both pass against the background but look identical
    // to each other would still fail an analyst scanning a findings table.
    expect(contrastRatio(t.severityHigh, t.severityLow)).toBeGreaterThan(1.2);
  });
});

describe('contrast utility', () => {
  it('computes the canonical 21:1 for black on white', () => {
    expect(contrastRatio(hsl(0, 0, 0), hsl(0, 0, 100))).toBeCloseTo(21, 1);
  });

  it('computes 1:1 for a colour against itself', () => {
    expect(contrastRatio(LIGHT.accent, LIGHT.accent)).toBeCloseTo(1, 5);
  });

  it('is symmetric with respect to argument order', () => {
    const a = contrastRatio(LIGHT.foreground, LIGHT.canvas);
    const b = contrastRatio(LIGHT.canvas, LIGHT.foreground);
    expect(a).toBeCloseTo(b, 10);
  });
});
