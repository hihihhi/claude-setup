# Color System — OKLCH

Use OKLCH, not HSL. HSL is not perceptually uniform — a green at `hsl(120, 50%, 50%)`
appears far brighter than a blue at `hsl(240, 50%, 50%)` even though the numbers are
identical. OKLCH fixes this. Same lightness and chroma values look the same across hues.

---

## OKLCH Syntax

```css
oklch(lightness% chroma hue)
/* lightness: 0% (black) → 100% (white)    */
/* chroma:    0 (gray)   → ~0.4 (vivid)    */
/* hue:       0–360 degrees                */
```

**Practical chroma ranges:**
- `0.00–0.01` — near-neutral, barely tinted
- `0.02–0.05` — tinted neutral (the sweet spot for backgrounds)
- `0.06–0.12` — muted tone
- `0.13–0.20` — clear color, not garish
- `0.21–0.35` — vivid, use sparingly for accents
- `0.35+` — maximum saturation, only for wordmarks/icons

---

## Building a Palette

### 1. Pick One Brand Hue
Everything derives from it. Avoid hue 270–310 (the AI purple range).

Good hue choices by product type:
- Developer tools: 220–240 (blue), 140–160 (teal), or 30–45 (amber)
- Creative/design: 30–50 (warm), 160–180 (cyan), or 0–10 (warm red)
- Finance/enterprise: 210–230 (steel blue), 40–55 (gold)
- Health/wellness: 140–160 (green) or 200–220 (clear blue)

### 2. Define Surface Tokens
Tinted neutrals feel alive without being colorful.

```css
:root {
  /* Light mode surfaces */
  --surface-base:  oklch(98% 0.005 var(--brand-h));  /* page bg */
  --surface-raised: oklch(100% 0 0);                  /* cards */
  --surface-sunken: oklch(94% 0.008 var(--brand-h));  /* inputs, wells */
  --surface-overlay: oklch(100% 0 0);                 /* modals */

  /* Dark mode surfaces */
  --surface-base-d:   oklch(14% 0.01 var(--brand-h));
  --surface-raised-d: oklch(18% 0.012 var(--brand-h));
  --surface-sunken-d: oklch(11% 0.008 var(--brand-h));
}
```

### 3. Define Text Tokens

```css
:root {
  --text-primary:   oklch(18% 0.01 var(--brand-h));  /* body, headings */
  --text-secondary: oklch(42% 0.01 var(--brand-h));  /* metadata, labels */
  --text-tertiary:  oklch(62% 0.01 var(--brand-h));  /* placeholders, hints */
  --text-on-accent: oklch(99% 0 0);                  /* text on accent bg */
}
```

**Never** use `opacity` to create secondary text. Always use a real lower-lightness token.
`opacity: 0.6` on white text over a colored background will fail contrast in dark contexts.

### 4. Define Accent Tokens

```css
:root {
  --accent:         oklch(54% 0.22 var(--brand-h));
  --accent-hover:   oklch(48% 0.22 var(--brand-h));
  --accent-subtle:  oklch(92% 0.04 var(--brand-h));
  --accent-on:      oklch(99% 0 0);                  /* text on accent */
}
```

### 5. Semantic Color Tokens

```css
:root {
  --color-success:     oklch(54% 0.18 145);
  --color-warning:     oklch(68% 0.18 70);
  --color-danger:      oklch(52% 0.22 25);
  --color-info:        oklch(56% 0.18 230);

  /* Subtle backgrounds for status areas */
  --color-success-subtle: oklch(94% 0.04 145);
  --color-warning-subtle: oklch(95% 0.04 70);
  --color-danger-subtle:  oklch(95% 0.04 25);
}
```

---

## Shadow System

Generic shadows look lifeless. Color-tint every shadow toward the surface it's on.

```css
/* Surface-tinted shadow */
.card {
  --shadow-color: oklch(75% 0.05 var(--brand-h));
  box-shadow:
    0 1px 2px oklch(from var(--shadow-color) l c h / 0.12),
    0 4px 8px oklch(from var(--shadow-color) l c h / 0.08);
}

/* Elevation system */
.elevation-1 { box-shadow: 0 1px 3px oklch(70% 0.04 var(--brand-h) / 0.12); }
.elevation-2 { box-shadow: 0 4px 12px oklch(65% 0.05 var(--brand-h) / 0.14); }
.elevation-3 { box-shadow: 0 8px 24px oklch(60% 0.06 var(--brand-h) / 0.16); }
```

---

## Contrast Accessibility

WCAG AA requires:
- Body text: 4.5:1 contrast ratio
- Large text (18px+ bold or 24px+ regular): 3:1
- UI components (borders, icons): 3:1

In OKLCH, lightness difference approximates contrast ratio:
- Text on white: `l < 45%` reliably passes 4.5:1
- Text on dark: `l > 70%` reliably passes 4.5:1
- Secondary text on white: `l < 62%` for 3:1 (large text)

Always verify with a real contrast checker — don't rely on rules of thumb for production.

---

## Dark Mode Rules

Dark mode is a separate design decision. Not an inversion.

1. **Surfaces are not inverted** — dark mode has its own depth hierarchy
2. **Chroma goes up slightly** in dark mode — muted colors look dull on dark
3. **Shadows disappear** — use border or glow instead for elevation
4. **Accent colors shift** — check that your light mode accent doesn't become garish at dark
5. **Never use `prefers-color-scheme` media query alone** — provide a manual toggle

```css
/* Correct dark mode approach */
[data-theme="dark"] {
  --surface-base: oklch(14% 0.01 var(--brand-h));
  --accent: oklch(62% 0.22 var(--brand-h));  /* lighter than light mode */
  --text-primary: oklch(92% 0.005 var(--brand-h));
}
```

---

## Common OKLCH Values Reference

| Use | OKLCH | Notes |
|-----|-------|-------|
| Near-black | `oklch(12% 0.01 250)` | Slightly blue-tinted |
| Dark surface | `oklch(17% 0.012 var(--h))` | Dark app background |
| Raised dark | `oklch(22% 0.015 var(--h))` | Cards on dark |
| Mid gray | `oklch(55% 0.01 var(--h))` | Secondary text |
| Light surface | `oklch(95% 0.006 var(--h))` | Tinted page bg |
| Near-white | `oklch(99% 0.002 var(--h))` | Card on light |
| Generic accent | `oklch(54% 0.22 var(--h))` | Primary button |
| Subtle accent bg | `oklch(93% 0.04 var(--h))` | Selected state |
| Danger red | `oklch(52% 0.22 25)` | Error states |
| Success green | `oklch(54% 0.18 145)` | Confirmations |
| Warning amber | `oklch(68% 0.18 70)` | Caution states |
