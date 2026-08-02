/**
 * WCAG 2.1 relative-luminance and contrast-ratio maths.
 *
 * Exists so that colour accessibility is an automated assertion rather than a
 * designer's judgement call. `design-tokens.test.ts` uses this to hold every
 * token pair in the palette to its required ratio.
 *
 * Reference: https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
 */

export interface Hsl {
  /** Hue in degrees, 0-360. */
  h: number;
  /** Saturation percentage, 0-100. */
  s: number;
  /** Lightness percentage, 0-100. */
  l: number;
}

export type Rgb = readonly [number, number, number];

/** Converts HSL to linear-scale sRGB channels in the range 0-1. */
export function hslToRgb({ h, s, l }: Hsl): Rgb {
  const saturation = s / 100;
  const lightness = l / 100;

  const c = (1 - Math.abs(2 * lightness - 1)) * saturation;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = lightness - c / 2;

  const sector = Math.floor(h / 60) % 6;
  const table: Rgb[] = [
    [c, x, 0],
    [x, c, 0],
    [0, c, x],
    [0, x, c],
    [x, 0, c],
    [c, 0, x],
  ];
  const [r, g, b] = table[sector] ?? [0, 0, 0];

  return [r + m, g + m, b + m];
}

/** WCAG relative luminance. */
export function relativeLuminance(rgb: Rgb): number {
  const [r, g, b] = rgb.map((channel) =>
    channel <= 0.03928 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4,
  ) as unknown as Rgb;

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/** Contrast ratio between two colours, from 1:1 to 21:1. */
export function contrastRatio(foreground: Hsl, background: Hsl): number {
  const a = relativeLuminance(hslToRgb(foreground));
  const b = relativeLuminance(hslToRgb(background));
  const lighter = Math.max(a, b);
  const darker = Math.min(a, b);

  return (lighter + 0.05) / (darker + 0.05);
}

/** WCAG minimum ratios by success criterion. */
export const WCAG = {
  /** 1.4.3 Contrast (Minimum) — body text. */
  AA_TEXT: 4.5,
  /** 1.4.3 — text at 18pt+, or 14pt+ bold. */
  AA_LARGE_TEXT: 3,
  /** 1.4.11 Non-text Contrast — interactive component boundaries, focus rings. */
  AA_NON_TEXT: 3,
  /** 1.4.6 Contrast (Enhanced). */
  AAA_TEXT: 7,
} as const;
