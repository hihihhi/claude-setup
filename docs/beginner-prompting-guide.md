# Beginner Prompting Guide — Claude Code

> **Goal:** With minimal effort, get Claude Code to do exactly what you want. This installation already does a lot automatically — but knowing what to say unlocks much more.

---

## Step 1: Set Your Role (Do This Every Session)

The single highest-leverage thing you can do:

```
load role developer
```

Other options: `researcher`, `designer`, `product`, `devops`, `data-scientist`

**Why it matters:** Without a role, you get general defaults. With `load role developer`, Claude routes "add a feature" through the full pipeline (plan → TDD → implement → review → PR) automatically. You say less and get more.

---

## The Core Rule: Tell Claude What Success Looks Like

Don't describe the action — describe the outcome.

| Vague (bad) | Goal-driven (good) |
|---|---|
| "add error handling" | "the API should return `{ error: 'title is required' }` with status 400 when title is missing" |
| "fix the bug" | "the login form should not submit when the password field is empty" |
| "improve performance" | "the dashboard should load in under 2 seconds on a 100k-row dataset" |
| "write tests" | "tests should catch: empty title (400), missing auth header (401), duplicate task (409)" |

---

## Phase Routing — Say These Phrases

| What you want | What to say |
|---|---|
| Start a new project | "new project: [description]" |
| Add a feature | "new feature: [description]" |
| Fix a bug | paste the error / stack trace — Claude routes it automatically |
| Refactor code | "refactor [function/file]" |
| Write tests | "write tests for [function]" or just `/tdd` |
| Code review | "review this" or `/code-review` |
| Create a PR | "ship" or "create a PR" |
| Research something | "deep research: [topic]" |

---

## Skill Invocation — The Slash Commands

Type these directly in the prompt:

```
/tdd              → Test-first development (failing test before any code)
/code-review      → Structured review: [CRITICAL/HIGH/MEDIUM/LOW] per finding
/security-review  → OWASP Top 10 audit
/refactor         → Clean up structure without changing behavior
/debug            → Reproduce → isolate → fix → verify
/deep-research    → 5-stage research with source tracking
/commit           → Conventional commit message from staged diff
/create-pr        → PR with summary and test plan
```

---

## The 4-Part Prompt Formula

```
[Context] + [Goal] + [Constraint] + [Format]
```

**Example (bad):**
```
add auth to the API
```

**Example (good):**
```
Context: Express API in api/src/routes/, using JWT stored in Authorization header
Goal: protect all routes except GET /health — return 401 if token missing or invalid
Constraint: don't change route signatures, add middleware only
Format: show the middleware file first, then which routes it attaches to
```

---

## Context Clarification Shortcuts

When Claude gives the wrong answer, add one of these:

```
"we don't mock the DB in tests — use a real DB connection"
"we use pnpm, not npm"
"match the style in [filename] exactly"
"only change the [function name] — don't touch anything else"
"no abstract classes — use interfaces"
"this is a hot path — optimize for performance over readability"
```

---

## Memory — Save Things Once, Never Repeat

```
remember that tests use a real database (no mocks)
remember that we're on a merge freeze until April 20
remember that the team prefers one PR per feature, not many small ones
```

After saving, you never need to repeat these preferences. They inject automatically on every prompt in this project.

---

## Multi-Agent Mode — When to Use It

```
"use team mode"         → spawns Architect + Implementer + Reviewer
"run in parallel"       → two independent tasks at the same time
"have a separate agent review this"  → independent code review
"use opus for this"     → upgrade to most capable model for hard decisions
```

**Rule of thumb:**
- Single file, quick fix → just ask directly
- 2–4 files, 1–2 hours → `use team mode`
- Multi-day feature → `use fleet mode`

---

## Context Management

```
/compact           → compress long conversation (keep going)
context reset      → fresh start, memory is preserved
```

Compact when you finish a chunk of work and are about to start something different. Don't wait until Claude starts repeating itself.

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| No role set | `load role developer` at session start |
| "make it better" | Say what "better" means: faster, simpler, more readable |
| Forgetting to mention the file | "in `api/src/routes/tasks.ts`" |
| Asking for everything at once | Break into 3–5 steps: plan → implement → test → review |
| Keeping 20 files open in editor | Open only what's relevant to the current task |
| Not checkpointing long sessions | `checkpoint: [what was accomplished]` every 30 min |

---

## Quick Reference Card

```bash
# Start every session
load role developer

# Plan first
plan: add stripe payment to the checkout flow

# Implement with TDD
implement the payment endpoint using TDD

# Independent review
have a separate agent review the stripe integration

# Ship
create a PR for the stripe-checkout branch

# Checkpoint before switching
checkpoint: stripe payment implemented, tests passing, PR open

# Next session
where were we?
```
