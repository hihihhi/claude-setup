---
name: deep-research
description: Multi-stage research pipeline with anti-sycophancy guards, IRON RULE
  context anchors, and provenance tracking. Use for thorough research tasks —
  academic analysis, competitive intelligence, technical investigation, or any
  topic where research quality matters more than speed. Invoke with /deep-research.
---

# Deep Research Pipeline

## When to use
- Thorough analysis (not quick lookups)
- When the topic needs cross-source verification
- When findings will inform decisions or documents
- Any research task > 20 minutes of effort

---

## Stage 1 — Frame the Research

Before searching anything, define:
1. **Core question** — one sentence, specific and falsifiable
2. **Success criteria** — what does a complete answer look like?
3. **Scope boundaries** — what is explicitly out of scope?
4. **Assumptions** — list them; they become verification targets

**IRON RULE — Research Frame:**
> The core question and success criteria defined in Stage 1 govern this entire research session.
> Do not drift from them. If new information suggests the question should change, stop and
> confirm with the user before pivoting.

---

## Stage 2 — Broad Sweep

Search across at least 3 source types:
- Primary sources (official docs, papers, raw data)
- Secondary sources (analysis, commentary, reviews)
- Contrary sources (criticism, alternative views, edge cases)

**Anti-sycophancy checkpoint:** After the broad sweep, rate your initial hypothesis:
- Has evidence strengthened it? (confirm bias risk)
- Has evidence weakened it? (update appropriately)
- Did you find evidence you initially wanted to dismiss?

Record your starting hypothesis and current confidence (0–100%) before proceeding.

---

## Stage 3 — Deep Dive

For each key claim from Stage 2:
1. Find the original source (not a summary of a summary)
2. Check publication date / recency
3. Note who made the claim and their potential bias
4. Find at least one source that challenges or qualifies the claim

**Concession scoring:** For every significant claim you accept, explicitly ask:
"What would a well-informed skeptic say?" Write it down, then evaluate it honestly.

---

## Stage 4 — Cross-Verification

Before synthesizing, run these checks:

| Check | Pass condition |
|-------|----------------|
| Source independence | Claims supported by sources that don't cite each other |
| Recency | Key facts are not outdated (check dates) |
| Contrary evidence | You actively searched for counter-evidence |
| Assumption audit | Each Stage 1 assumption tested against findings |

**IRON RULE — Verification Gate:**
> Do not proceed to synthesis until at least 3 independent sources confirm each
> key claim. Single-source claims must be labeled as unverified.

---

## Stage 5 — Synthesize

Structure findings as:
```
## Core Answer
[Direct answer to the Stage 1 question]

## Evidence Summary
[Key supporting findings with source citations]

## Contrary Evidence
[What the skeptic would argue; how strong is it?]

## Confidence Rating
[0-100%] — [brief justification]

## Limitations
[What this research couldn't determine; what would increase confidence]

## Sources
[Cited with date and type: primary/secondary/contrary]
```

---

## Anti-Sycophancy Rules

These rules prevent the research from drifting toward confirming what you expect to find:

1. **Intent detection:** Before each search query, ask "Am I searching for confirmation or for truth?" If confirmation, deliberately search for the opposite first.

2. **Dialogue health:** If the last 3 findings all agree, that's a signal to look harder for dissent. Agreement clusters are often filter bubbles.

3. **Concession floor:** At least 20% of findings must challenge the core hypothesis. If you can't find any, document that failure — it's a data point, not a clean win.

4. **User alignment, not user pleasing:** If findings contradict what the user expected, report them clearly. Do not soften findings to match user expectations.

---

## Material Passport (Provenance Tracking)

For research that will be cited in documents, maintain a source ledger:

```
Source: [URL or citation]
Type: [primary / secondary / contrary]
Date accessed: [date]
Key claim extracted: [one sentence]
Confidence in claim: [high/medium/low]
Used in: [section of synthesis where cited]
```

This ensures findings are traceable from synthesis back to original source.

---

## Depth Modes

| Mode | Use when | Stages |
|------|----------|--------|
| **flash** | Quick orientation, 5-10 min | 1, 2, 5 |
| **standard** | Solid research, 30-60 min | 1-3, 5 |
| **pro** | Thorough analysis, 1-2 hrs | 1-5 |
| **deep** | Exhaustive, multi-source, 2+ hrs | 1-5 + parallel sub-queries |

Default to **standard** unless told otherwise.

---

## IRON RULE — Final Output

> Every factual claim in the synthesis must have a source in the Material Passport.
> Unsourced claims must be labeled [INFERRED] or [UNVERIFIED].
> The confidence rating must be honest — not inflated to seem more authoritative.
