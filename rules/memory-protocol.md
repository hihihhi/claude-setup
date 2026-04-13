# Memory Protocol
> Always-loaded. Source: learn-claude-code/s09, hermes-agent four-layer model.

## The Four Memory Types

| Type | What it stores | Example |
|------|---------------|---------|
| `user` | Role, preferences, communication style | "Prefers terse responses; deep Go expertise, new to React" |
| `feedback` | Corrections + validated approaches | "Don't mock DB in tests — prod migration failed last quarter" |
| `project` | Non-obvious facts tied to ONE project | "Legacy dir deletion breaks deployment pipeline" |
| `reference` | Pointers to external systems | "Bugs tracked in Linear/INGEST project" |

## CLAUDE.md vs Memory vs Tasks vs Plans

| Container | What it holds | Scope |
|-----------|-------------|-------|
| CLAUDE.md | Standing rules for ALL tasks | Permanent, always-loaded |
| Memory files | Facts that persist across sessions | Permanent, loaded on relevance |
| Tasks | Progress for the CURRENT conversation | Session-scoped only |
| Plans | Implementation strategy for CURRENT task | Session-scoped only |

**Test:** "Would I need to tell Claude this again in a new session?" → Yes = memory. No = task/plan.

## What NOT to Save in Memory

Never save — re-derive from the actual source instead:

- File paths, function names, code patterns → read the code
- Git history, who changed what → `git log`, `git blame`
- Current task progress → that's Tasks
- Debugging solutions or fix recipes → the fix is in the code
- PR lists, activity summaries → `git log` is authoritative
- Anything in CLAUDE.md already
- Architecture snapshots → stale fast, read the repo instead

## Save Triggers

Save immediately (don't batch until end of session):

1. **User corrects behavior** → feedback memory (the correction + why + how to apply)
2. **User reveals role/preferences** → user memory
3. **Non-obvious project fact learned** → project memory (what, why, how to apply)
4. **User points to external resource** → reference memory

## File Format

```markdown
---
name: Short descriptive name
description: One-line hook — used by memory-search.py for relevance scoring
type: user | feedback | project | reference
---

[Content. For feedback/project: lead with the rule/fact, then **Why:** and **How to apply:** lines]
```

## MEMORY.md Index Rules

- One entry per memory file, ≤ 150 characters
- Format: `- [Title](file.md) — one-line hook`
- Index entries after line 200 are truncated → keep it tight
- Never write memory content directly into MEMORY.md
