# No AI Slop — Banned Patterns

This file is the canonical anti-pattern list for frontend output. Check every component
against it before calling the work done.

---

## Typography Anti-Patterns

| Pattern | Why it's banned | Fix |
|---------|-----------------|-----|
| `font-family: Inter, sans-serif` as the only choice | Commodity default. Signals no decision was made | Pick a face with personality — or at least pair Inter with a display font |
| Monospace for decoration | Overused AI shorthand for "technical" | Earn monospace by using it where it's actually appropriate (code, IDs, data) |
| Large heading + small body in the same weight | Creates no hierarchy, just size variation | Vary weight AND size together |
| Full-width body text | Destroys readability after ~80 chars | Max width 65ch on body copy containers |
| Identical letter-spacing across all text | Spacing should tighten at large sizes, open at small | Scale tracking inversely with size |

---

## Color Anti-Patterns

| Pattern | Why it's banned | Fix |
|---------|-----------------|-----|
| Purple gradient hero (`#6366f1 → #8b5cf6`) | The canonical AI color signature | Use OKLCH, pick a hue with brand meaning |
| Gray text on colored surface | Fails contrast math unpredictably | Use OKLCH lightness ratio — check programmatically |
| `rgba(0,0,0,0.1)` generic shadow | Looks lifeless, no hue relationship | Tint shadow toward the surface color: `oklch(var(--surface-l) calc(var(--surface-c) * 0.5) var(--surface-h))` |
| Dark mode = `color: white; background: #111` | No thought given to depth or hierarchy | Define separate surface tokens for dark: `--surface-1`, `--surface-2`, etc. |
| Pure black `#000000` or `#111111` | Harsh, looks cheap | `oklch(12% 0.01 250)` — slightly blue-tinted black |
| Gradient text (`background-clip: text`) for impact | Overused, often fails on different backgrounds | Use gradient text only for wordmark/display, never for hierarchy |
| One accent color doing all the work | Monotonous, no semantic color | Assign semantic roles: primary action, warning, success, destructive |
| Saturation cliff between backgrounds | Jarring transitions | Tinted neutrals with consistent chroma family |

---

## Layout Anti-Patterns

| Pattern | Why it's banned | Fix |
|---------|-----------------|-----|
| Cards inside cards inside cards | Nesting creates visual noise with no hierarchy | One level of cards max; use spacing/color for inner grouping |
| Identical card grid (4 columns, uniform spacing) | Template aesthetics — looks like Tailwind docs | Break grid: vary cell sizes, create rhythm with gaps |
| `margin: 16px` everywhere | Uniform spacing erases hierarchy | Derive spacing from line-height base unit; vary by context |
| `border-radius: 12px` on everything | Rounds edges for no reason, signals laziness | Choose one radius value and use it purposefully, or go full sharp |
| Centered layout with centered text | Destroys reading flow beyond a sentence | Center only splash/hero when justified; body content left-aligns |
| Sidebar + content + widget column default | Dashboard-by-numbers | Design for the information architecture, not the template |

---

## Visual Detail Anti-Patterns

| Pattern | Why it's banned | Fix |
|---------|-----------------|-----|
| Glassmorphism as personality | `backdrop-filter: blur(10px)` on every surface signals nothing | Reserve blur for genuine layering (modals over live content) |
| Colorful left border as design element | Lazy "we added color" — substitutes for real design | Use color to mean something (status, category, hierarchy) |
| Decorative sparklines / animated graphs | Motion without information | Animate only when it shows change happening |
| `box-shadow: 0 4px 6px rgba(0,0,0,0.07)` default | Generic, ubiquitous, invisible | Color-tinted shadow at correct elevation for the surface |
| `opacity: 0.7` on secondary text | Blunt. Creates contrast issues on non-white backgrounds | Use a real lower-lightness color token |
| Emoji as icon substitute in interfaces | Inconsistent rendering, no semantic role | SVG icons with proper sizing and aria-label |

---

## Interaction Anti-Patterns

| Pattern | Why it's banned | Fix |
|---------|-----------------|-----|
| No hover state | Invisible interactivity | Every clickable element has a distinct hover AND focus state |
| Focus ring removed (`outline: none`) without replacement | Kills keyboard accessibility | `outline: 2px solid var(--accent); outline-offset: 2px` |
| Bounce/elastic easing | Felt fresh in 2018 | `cubic-bezier(0.16, 1, 0.3, 1)` (ease out expo) for most entrances |
| Animating `width`, `height`, `top`, `left` | Triggers layout, causes jank | Use `transform` and `opacity` only |
| All buttons are primary style | No action hierarchy | Max one primary per screen; secondary and ghost for other actions |
| Modal for everything | Interrupts context for non-critical choices | Use inline validation, toast notifications, or slide-over panels |
| Loading spinner for fast operations (<200ms) | Creates flicker | Delay spinner reveal by 200ms; use optimistic UI where possible |

---

## Component-Specific Patterns

### Hero Sections
- NOT: Centered headline + gradient blob + generic CTA button
- YES: Asymmetric composition, editorial type, specific product context

### Navigation
- NOT: Logo left, links center, CTA button right, full-width top bar
- YES: Navigation that reflects the product hierarchy, not a template

### Data Tables
- NOT: Default HTML table with alternating gray rows
- YES: Compact density, proper numeric formatting (right-align numbers), sortable columns with visible affordance

### Empty States
- NOT: Centered illustration + "No items yet" + "Create your first X" button
- YES: Empty state specific to the task context — what would help the user *now*?

### Forms
- NOT: All fields stacked, all labels above, all errors below
- YES: Inline validation, contextual help, logical field grouping, single primary action

---

## Audit Checklist

Before shipping any frontend surface:

- [ ] No `font-family: Inter` without a pairing decision
- [ ] No pure black (#000000) or default gray
- [ ] No `rgba(0,0,0,0.1)` box shadows
- [ ] No gradient text for hierarchy
- [ ] Hover AND focus states on every interactive element
- [ ] No `outline: none` without a custom replacement
- [ ] No bounce/elastic easing
- [ ] No card nesting beyond one level
- [ ] Body copy measure ≤ 75ch
- [ ] Color contrast passes WCAG AA (OKLCH lightness difference ≥ 0.4 for body text)
- [ ] Dark mode is a separate palette decision, not an inversion
- [ ] Would this look believable in a real product screenshot?
