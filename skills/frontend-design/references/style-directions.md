# Style Directions

Each direction is a complete visual system. Pick one. Do not blend them without intention.

---

## Getting Brand DESIGN.md Files

[getdesign.md](https://getdesign.md) hosts 55+ DESIGN.md files extracted from real brand
design systems. Drop the relevant file into your project root to ground Claude Code's
output in a real visual identity.

**Available brand systems include:**
- **AI/LLM**: Claude (Anthropic), Mistral, Together AI, x.ai
- **Dev tools**: Stripe, Vercel, Linear, Figma
- **Productivity**: Cal.com, Slack, Notion
- **Consumer**: Uber, Tesla, Netflix
- **Fintech/Crypto**: various

These are particularly useful when building:
- A product that lives in the same ecosystem as one of these brands
- A product that competes with one and needs to feel comparable in quality
- Any project where the client points to one of these as a reference

---

## Direction: Editorial / Magazine

**When to use:** Content-heavy, serious, journalism, publishing, high-end B2B

**Signature:**
- Serif for headings, sans for body (or all-serif at a disciplined scale)
- Asymmetric layouts — left-heavy, column-grid with active whitespace
- Large type moments broken by tight data-dense sections
- Black/off-white primary palette, one accent
- Photography as primary visual element

**CSS pattern:**
```css
:root {
  --font-display: 'Playfair Display', Georgia, serif;
  --font-body: 'DM Sans', system-ui, sans-serif;
  --color-ink: oklch(14% 0.008 240);
  --color-paper: oklch(97% 0.004 60);
  --color-accent: oklch(52% 0.20 25);  /* warm red */
}

.article-body { max-width: 68ch; line-height: 1.65; }
.section-label { font-family: var(--font-body); font-size: 0.75rem; letter-spacing: 0.1em; text-transform: uppercase; }
.pull-quote { font-family: var(--font-display); font-size: 1.75rem; font-style: italic; border-left: 3px solid var(--color-accent); padding-left: 1.5rem; }
```

---

## Direction: Neo-Brutalism

**When to use:** Dev tools, disruptors, games, creative tools targeting 18–35 audience

**Signature:**
- No border-radius (or max 2px)
- Flat color with bold black borders (`border: 2px solid black`)
- High-contrast, intentionally "raw" aesthetic
- `transform: translate(2px, 2px)` hover state with offset shadow
- Loud accent colors (chartreuse, hot pink, electric blue)

**CSS pattern:**
```css
.card {
  border: 2px solid oklch(12% 0 0);
  border-radius: 0;
  box-shadow: 4px 4px 0 oklch(12% 0 0);
  transition: transform 120ms ease, box-shadow 120ms ease;
}
.card:hover {
  transform: translate(2px, 2px);
  box-shadow: 2px 2px 0 oklch(12% 0 0);
}
.btn-primary {
  background: oklch(78% 0.25 130);  /* chartreuse */
  color: oklch(12% 0 0);
  border: 2px solid oklch(12% 0 0);
  border-radius: 0;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
```

---

## Direction: Bento / Grid

**When to use:** Dashboards, feature showcases, marketing pages, SaaS landing pages

**Signature:**
- Asymmetric grid cells with varied sizes (not uniform card grid)
- Intentional rhythm through gap variation
- Each cell has a single purpose/moment
- Mixed content types: text, chart, image, number — not all the same
- Rounded corners are allowed but must be consistent

**CSS pattern:**
```css
.bento-grid {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: 16px;
}
/* Vary cell sizes — never 4 equal columns */
.bento-hero  { grid-column: span 8; grid-row: span 2; }
.bento-stat  { grid-column: span 4; }
.bento-chart { grid-column: span 5; grid-row: span 2; }
.bento-cta   { grid-column: span 7; }
```

---

## Direction: Swiss / International

**When to use:** Enterprise, finance, data-heavy applications, legal tech

**Signature:**
- Strict 12-column grid, no breaking it
- Neutral palette — blue-gray or warm gray, one measured accent
- Geometric sans (Helvetica Neue, Neue Haas Grotesk, or Aktiv Grotesk)
- No decorative elements — information IS the design
- Dense but readable — tight line-height on data, generous leading on prose

**CSS pattern:**
```css
:root {
  --grid: repeat(12, 1fr);
  --col-gap: 24px;
  --row-gap: 32px;
  --font-main: 'Neue Haas Grotesk', 'Helvetica Neue', Helvetica, sans-serif;
  --color-bg: oklch(97% 0.004 220);
  --color-fg: oklch(18% 0.01 220);
  --color-rule: oklch(82% 0.01 220);  /* borders */
  --color-accent: oklch(50% 0.22 230);  /* precise blue */
}
.section { border-top: 1px solid var(--color-rule); padding-top: 32px; }
```

---

## Direction: Dark Luxury

**When to use:** Premium SaaS, financial tools, AI products, anything with a high price point

**Signature:**
- Deep near-black surfaces — not `#111`, but warm/tinted dark
- Restrained accent: amber, copper, soft gold, or muted blue
- Generous spacing — density signals "cheap"
- No pure white text — warm off-white
- Subtle gradient only on key surface transitions

**CSS pattern:**
```css
:root {
  --surface-base:   oklch(13% 0.012 45);   /* warm near-black */
  --surface-raised: oklch(18% 0.015 45);
  --surface-border: oklch(28% 0.015 45);
  --text-primary:   oklch(92% 0.006 60);   /* warm off-white */
  --text-secondary: oklch(65% 0.006 60);
  --accent:         oklch(72% 0.14 65);    /* muted amber */
  --accent-glow: oklch(72% 0.14 65 / 0.15);
}
.premium-card {
  background: var(--surface-raised);
  border: 1px solid var(--surface-border);
  box-shadow: 0 0 0 1px oklch(100% 0 0 / 0.04) inset;
}
```

---

## Direction: Retro-Futurism

**When to use:** Creative tools, AI products, design tools, gaming-adjacent

**Signature:**
- Terminal green / amber / phosphor palette on near-black
- Monospace as a personality element (for UI labels, not just code)
- CRT scanline texture (CSS, subtle)
- Geometric/technical precision mixed with organic type
- Grid-based composition with deliberate spacing

**CSS pattern:**
```css
:root {
  --color-phosphor: oklch(72% 0.22 140);   /* terminal green */
  --color-bg: oklch(10% 0.015 140);
  --color-surface: oklch(14% 0.018 140);
  --color-border: oklch(25% 0.04 140);
  --font-mono: 'JetBrains Mono', 'Berkeley Mono', monospace;
}
/* Scanline texture */
body::before {
  content: '';
  position: fixed; inset: 0;
  background: repeating-linear-gradient(
    0deg,
    transparent,
    transparent 2px,
    oklch(0% 0 0 / 0.03) 2px,
    oklch(0% 0 0 / 0.03) 4px
  );
  pointer-events: none; z-index: 9999;
}
```

---

## Motion — Cross-Direction Rules

These apply regardless of which style direction you choose.

```css
/* Preferred easing curve for UI elements */
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
--ease-in-out:   cubic-bezier(0.45, 0, 0.55, 1);
--ease-spring:   cubic-bezier(0.34, 1.3, 0.64, 1);  /* subtle spring only */

/* Durations */
--dur-instant:  80ms;   /* state changes (toggle, check) */
--dur-fast:    160ms;   /* hover effects */
--dur-base:    250ms;   /* enter/exit transitions */
--dur-slow:    400ms;   /* page transitions, major reveals */

/* Never: */
/* cubic-bezier with values > 1.5 (exaggerated bounce) */
/* animation-duration > 600ms for UI feedback */
/* Animating width/height/top/left (always use transform) */
```

**Staggering pattern for lists:**
```css
.list-item { animation: slide-up var(--dur-base) var(--ease-out-expo) both; }
.list-item:nth-child(1) { animation-delay: 0ms; }
.list-item:nth-child(2) { animation-delay: 40ms; }
.list-item:nth-child(3) { animation-delay: 80ms; }
/* Max 5 stagger levels — after that, delay the whole container instead */
```
