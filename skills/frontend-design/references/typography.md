# Typography

Typography is where most AI-generated UIs fail first. Inter on everything,
one weight, no pairing logic. The fix is a decision — not a different font.

---

## The Decision Framework

Before picking a font, answer:
1. What emotional register? (Warm/cold, playful/serious, human/precise)
2. Is there reading-heavy content or mostly labels/data?
3. Does the product have a "voice" that typography should reinforce?
4. What's the target rendering environment? (HiDPI screen / 1080p / print)

---

## Font Pairing Strategies

### Strategy A: One Face, Two Roles
Use a variable font with enough range to serve both display and body.
- Display: high weight (800–900), large size, tight tracking
- Body: mid weight (400–450), normal tracking

Works well: Fraunces, Syne, Instrument Sans

### Strategy B: Serif Display + Sans Body
Classic editorial contrast. Serif for personality, sans for readability.
- Display: `Playfair Display`, `DM Serif Display`, `Lora`, `Freight Display`
- Body: `DM Sans`, `Manrope`, `Plus Jakarta Sans`

Avoid: mixing two fonts that feel similar in weight and style — creates visual noise.

### Strategy C: Geometric + Humanist
Precise/structured headline, warm/readable body.
- Display: `Space Grotesk`, `Outfit`, `Clash Display`, `Cabinet Grotesk`
- Body: `Lato`, `Source Sans 3`, `Nunito`

### Strategy D: Monospace Accent
For developer tools or technical products where monospace has semantic meaning.
- Body/headings: Any sans
- Code/data/IDs: `JetBrains Mono`, `Geist Mono`, `Berkeley Mono`
- Use monospace ONLY for actual code, IDs, numbers — never as decoration

---

## Fonts Worth Using

**Display / Heading:**
- `Fraunces` — Variable, quirky serif with beautiful optical sizes
- `Clash Display` — Geometric, contemporary, distinctive at large sizes
- `Space Grotesk` — Technical edge, good for developer tools
- `Cabinet Grotesk` — Editorial, variable, unusual character shapes
- `Syne` — Unique letterforms, strong personality
- `Instrument Serif` — Elegant, neutral, high readability serif
- `DM Serif Display` — Clean, modern serif for product headings

**Body:**
- `Lora` — Warm, readable, good for prose-heavy content
- `DM Sans` — Clean, modern, pairs well with most display faces
- `Plus Jakarta Sans` — High-x-height, contemporary, energetic
- `Manrope` — Geometric, friendly, tech-adjacent
- `Source Sans 3` — Neutral, highly readable, enterprise contexts

**Monospace (for code/data only):**
- `JetBrains Mono` — Ligature-rich, developer standard
- `Geist Mono` — Vercel's monospace, clean and modern
- `Berkeley Mono` — Premium, distinctive, character

**Fonts to avoid (commodity defaults):**
- Inter — Not bad, just decided for you; pair with something if you use it
- Helvetica / Arial — No personality
- System UI / -apple-system — Invisible, not a design choice
- Roboto — Android default, nothing distinctive

---

## Type Scale

Use a modular scale. Base: `1rem` (16px), ratio: `1.25` (Major Third) or `1.333` (Perfect Fourth).

**Major Third scale (1.25):**
```
xs:   0.64rem  (10.2px)  — labels, metadata
sm:   0.8rem   (12.8px)  — captions, timestamps
base: 1rem     (16px)    — body text
md:   1.25rem  (20px)    — lead text, large labels
lg:   1.563rem (25px)    — h3, section titles
xl:   1.953rem (31.3px)  — h2, feature headings
2xl:  2.441rem (39px)    — h1, page titles
3xl:  3.052rem (48.8px)  — display / hero headings
```

**Rules:**
- Don't use more than 5 distinct sizes in one interface
- Vary weight alongside size — size alone creates weak hierarchy
- Reserve the largest 1–2 sizes for genuine feature moments

---

## Spacing & Rhythm

**Base unit = `line-height × font-size`**

If body is 16px with `line-height: 1.5`, base unit = 24px.

Vertical spacing should be multiples or halves:
- `6px` (base/4) — tight: within a component
- `12px` (base/2) — related items
- `24px` (base) — paragraph spacing
- `48px` (base×2) — section breaks
- `96px` (base×4) — major section separators

**Tracking (letter-spacing) rules:**
- Display (> 40px): `-0.02em` to `-0.04em` — tight
- Body (16–20px): `0` — no adjustment
- Labels (< 13px): `+0.02em` to `+0.06em` — open up small text
- All-caps text always: `+0.05em` to `+0.12em`

---

## Measure (Line Length)

| Content type | Max width | Notes |
|---|---|---|
| Long-form prose | 65ch | Essential for readability |
| Body copy | 70–75ch | Standard range |
| UI labels | unlimited | Context-dependent |
| Code | unlimited | Never truncate code |

Never `width: 100%` on prose containers.

---

## Hierarchy Rules

1. **Primary hierarchy cue**: weight (not just size)
2. **Secondary cue**: size
3. **Tertiary cue**: color/opacity (carefully — see color system)

Headings should feel larger AND heavier than body. If your `h2` is just larger Inter 400,
there's no hierarchy — only scale variation.

Avoid:
- Same weight for all text levels
- More than 3 levels of hierarchy in one viewport
- Centered body text beyond two lines
