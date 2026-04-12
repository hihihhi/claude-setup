---
name: frontend-design
description: >
  Anti-AI-slop frontend design skill. Triggered for CSS/UI work, visual design, component styling,
  and any task where the output must not look like an unmodified template. Enforces OKLCH color,
  intentional typography, and opinionated style direction over safe defaults.
triggers:
  - CSS / UI work
  - design component
  - make it look good
  - style this
  - frontend design
  - visual design
  - "looks generic"
  - "looks like AI"
---

# Frontend Design — No AI Slop

> The goal is not to look designed. It is to look *decided*.

Generic AI output has a specific signature: Inter font, purple gradient, centered hero,
card grid with uniform shadow, dark mode that's just inverted light mode. This skill
exists to break that signature at every touchpoint.

## Step 0: Gather Context (Once Per Project)

Before any design work, capture the project's visual identity. Save to `.claude-design.md`
in the project root so you never re-ask the same questions.

```markdown
# .claude-design.md
product_type:     # SaaS / consumer / creative / data / e-commerce / docs
audience:         # developers / executives / general / domain experts
tone:             # serious / playful / sophisticated / raw / clinical
primary_action:   # what is the ONE thing this UI helps users do?
avoid:            # client's explicit "never do this" list
references:       # 1-3 URLs the client points to as inspiration
```

Check `.claude-design.md` at the start of every CSS/UI task. If it does not exist,
create it with gathered context before writing a single line of CSS.

---

## Style Direction

Pick ONE direction before writing code. "Clean minimal" is not a direction.
State the direction explicitly in the design context file.

| Direction | When to use | Key signature |
|-----------|-------------|---------------|
| Editorial | Content-heavy, serious | Large type, asymmetric layout, white space as structure |
| Neo-Brutalism | Dev tools, disruptors, games | No rounded corners, flat color, thick borders, intentional roughness |
| Bento / Grid | Dashboards, feature showcases | Asymmetric cells, varied rhythm, grouped whitespace |
| Swiss / International | Enterprise, data, finance | Grid discipline, neutral palette, geometric type |
| Dark Luxury | Premium, financial, AI products | Deep neutrals, subtle gold/copper, restrained color |
| Retro-Futurism | Creative tools, AI, design tools | Monospace + serif contrast, phosphor palette, scan-line texture |
| 3D Integration | Gaming, spatial, experiential | CSS 3D perspective, WebGL accent, real depth |

For brand design system references (Stripe, Vercel, Linear, Claude, etc.) see
[getdesign.md](https://getdesign.md) — drop the relevant DESIGN.md into the project.

---

## Color System (OKLCH)

Use OKLCH, not HSL. OKLCH is perceptually uniform — same chroma and lightness
*actually looks* the same across hues. See [references/color-oklch.md](references/color-oklch.md).

**Quick rules:**
- Never pure black. Use `oklch(12% 0.02 250)` — slightly blue-tinted.
- Never pure gray. Use `oklch(65% 0.01 60)` — slightly warm.
- Tinted neutrals = brand personality. `oklch(95% 0.01 60)` feels warm, not sterile.
- Shadow color must match the surface hue. No generic `rgba(0,0,0,0.1)`.
- Dark mode is a separate palette decision, not `filter: invert(1)`.

---

## Typography

See [references/typography.md](references/typography.md) for full system.

**Quick rules:**
- Inter is the default. Default means you made no decision. Make one.
- Minimum 2 weights if using one family. If it doesn't have a clear bold, it's decorative.
- Line-height is the base unit for vertical rhythm. 16px × 1.5 = 24px base.
- All vertical spacing derives from multiples/halves of that base unit.
- Measure (line length): 55–75 characters for body copy. Never 100%.

---

## Anti-Patterns

Full list: [references/no-ai-slop.md](references/no-ai-slop.md)

**Never ship these:**
- Purple gradient + white text hero
- Gray text on a colored surface (check contrast in OKLCH)
- `border-radius: 12px` on everything
- Cards inside cards inside cards
- All primary buttons (no action hierarchy)
- Bounce/spring easing (`cubic-bezier` with values > 1)
- Glassmorphism as a personality substitute
- `font-family: Inter` without a pairing decision
- Centered everything (centered layout kills hierarchy)
- Uniform margin/padding values across all elements

---

## Workflow

```
1. Read .claude-design.md (create if missing)
2. State the chosen style direction
3. Define palette in OKLCH (3–5 tokens max)
4. Define type scale (2 faces, 4–6 sizes)
5. Write the component / layout / page
6. Self-audit using [references/no-ai-slop.md](references/no-ai-slop.md) checklist
7. Polish: hover/focus/active states, motion, edge cases
```

---

## Slash Commands

These map to specific design tasks:

| Command | What it does |
|---------|--------------|
| `/colorize` | Add strategic color without destroying the layout |
| `/typeset` | Fix font choices, hierarchy, sizing, measure |
| `/animate` | Add purposeful motion (entry, hover, state transitions) |
| `/critique` | UX review: hierarchy, clarity, emotional resonance |
| `/polish` | Final pass: states, shadows, micro-details, edge cases |
| `/bolder` | Amplify a design that's too timid |
| `/quieter` | Tone down a design that's too loud |

---

## References

- [no-ai-slop.md](references/no-ai-slop.md) — Full banned patterns list
- [color-oklch.md](references/color-oklch.md) — OKLCH system, tinting, accessibility
- [typography.md](references/typography.md) — Font choices, scale, rhythm
- [style-directions.md](references/style-directions.md) — Per-direction specs + code examples
- [getdesign.md](https://getdesign.md) — 55+ brand DESIGN.md files (Stripe, Vercel, Linear, Claude, etc.)
