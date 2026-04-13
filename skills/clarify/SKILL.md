---
name: clarify
description: >
  Structured clarification interview before acting on complex or ambiguous requests.
  Identifies every gap, missing piece, or ambiguous term in the user's request and
  asks about each one. User fills in the blanks. Only then does Claude proceed.
  Opposite of prompt-master: Claude never rewrites your intent — you state it fully.
triggers:
  - /clarify
  - not sure what you mean
  - make sure you understand
  - ask me first
  - what do you need to know
  - before you start, ask
---

# Clarify — Structured Pre-Action Interview

> Prompt-master rewrites your prompt for you. This skill asks you to fill in the blanks
> yourself. Your intent stays yours. Claude just maps the gaps.

## When to invoke

- Triggered explicitly with `/clarify` before describing a task
- Or invoked by Claude when it detects genuinely high ambiguity (see rules below)
- NOT automatic on every message — that would be noise

---

## Workflow

### Step 1: Read the Request

Read the user's message. Parse it for the following gap types:

| Gap type | Example | Question to ask |
|----------|---------|-----------------|
| Missing subject | "refactor this" | Which file/component/function? |
| Missing scope | "improve performance" | What's the target? What's the baseline? |
| Ambiguous term | "make it better" | Better in what dimension — speed, readability, UX, size? |
| Conflicting signals | "fast but also flexible" | Which wins when they conflict? |
| Missing output format | "analyze this data" | What do you want back — table, chart, prose, numbers? |
| Missing context | "fix the bug" | What bug? What's the expected vs actual behavior? |
| Missing constraint | "build a login system" | Which stack? Auth method? Existing schema? |
| Implicit assumption | "like we did before" | Which previous implementation? |
| Unclear success criterion | "make it work" | What does working look like? How will you verify? |

### Step 2: List Every Gap

Present ALL gaps as a numbered list. Do not ask a single "most important" question —
ask all of them. The user deserves to know every dimension where their request was unclear.

Format:
```
Before I start, a few things I need to know:

1. [Gap 1 — state what's missing and why it matters for the task]
2. [Gap 2]
3. [Gap 3]
...

Answer whichever you know — leave blank anything you want me to decide.
```

The last line is important: the user chooses what to delegate vs what to specify.
If they leave something blank, THEN Claude can make a reasonable default — but
it states the default explicitly: "I'll assume X unless you say otherwise."

### Step 3: Receive Answers

After the user responds:
- Map each answer to its gap
- For any blanks: state the default you'll use and flag it
- For any conflicting answers: surface the conflict and ask to resolve

Do not proceed until the user has seen the full clarified understanding.

### Step 4: Confirm Understanding

Before starting, restate the complete, clarified task in your own words:

```
Got it. Here's what I'll do:
- [Restated goal with all gaps filled]
- [Key decisions: what you specified vs what I defaulted]
- [What I will NOT do — scope boundaries]

Anything wrong with that picture?
```

Proceed only when the user confirms or makes corrections.

---

## When Claude Invokes This Itself (Without Being Asked)

Claude may invoke clarify mode autonomously when ALL of these are true:

1. The request has **3 or more** genuine gaps (not just stylistic choices)
2. Acting on a wrong assumption would waste **significant work** (> 30 minutes of effort)
3. There is **no way to verify** correctness without user confirmation mid-task

In this case, Claude states upfront:
```
Before I start — this request has several open questions I shouldn't guess at.
Let me map them:
[gap list]
```

Claude does NOT invoke this for:
- Simple requests with one obvious interpretation
- Tasks where the user can easily course-correct in one turn
- Requests where context is fully clear from the current codebase

---

## What This Is NOT

- **Not prompt rewriting** — Claude never changes what you meant; you state your full intent
- **Not interrogation** — gaps are explained, not demanded
- **Not a blocker** — user can always say "just use your best judgment on everything" and Claude will proceed with stated defaults
- **Not automatic** — never runs unless invoked or genuinely needed

---

## Anti-Patterns to Avoid

| Wrong | Right |
|-------|-------|
| Ask only the "most important" question | Ask all genuine gaps |
| Silently assume and proceed | State the assumption, let user confirm or override |
| Rewrite the request to fill gaps | Present gaps, let user fill them |
| Ask about things that don't affect the outcome | Only ask when the answer changes what you'd do |
| Batch all questions into one confusing paragraph | Numbered list, one gap per item |
