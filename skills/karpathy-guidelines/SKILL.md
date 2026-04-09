---
name: karpathy-guidelines
description: Behavioral guidelines to reduce common LLM coding mistakes. Use
  when writing, reviewing, or refactoring code to avoid overcomplication, make
  surgical changes, surface assumptions, and define verifiable success criteria.
  Auto-triggers on all implementation tasks.
license: MIT
attribution: Patterns from forrestchang/andrej-karpathy-skills (MIT)
---

# Karpathy Coding Guidelines

These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

- State assumptions explicitly. If uncertain, ask.
- When multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

**Anti-pattern:** Silently assuming file format, scope, or fields → List assumptions, ask first.

## 2. Simplicity First

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

**Self-test:** "Would a senior engineer say this is overcomplicated?" If yes, simplify.

**Anti-pattern:** Strategy pattern / dataclass / Protocol for a single calculation → 3-line function.

## 3. Surgical Changes

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

**Self-test:** Every changed line should trace directly to the user's request.

**Anti-pattern:** Fixing a bug + reformatting quotes + adding type hints → Only fix the bug.

## 4. Goal-Driven Execution

Transform imperative tasks into verifiable goals:

| Imperative | Goal |
|-----------|------|
| "Add validation" | Write tests for invalid inputs, then make them pass |
| "Fix the bug" | Write a test that reproduces it, then make it pass |
| "Refactor X" | Ensure tests pass before and after |

For multi-step tasks, state a brief plan with verification at each step:

```
1. [Step] -> verify: [check]
2. [Step] -> verify: [check]
3. [Step] -> verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification — ask for clarification before starting.

**Success indicators:** Fewer unnecessary changes in diffs, fewer rewrites, clarifying questions come before implementation rather than after mistakes.
