---
name: self-evolve
description: >
  Self-improvement loop for the Claude Code harness. Reviews session history,
  identifies patterns in failures and feedback, and proposes targeted updates to
  skills, routing tables, and CLAUDE.md. Inspired by hermes-agent GEPA pattern.
  Always requires human approval before any change is applied.
triggers:
  - /self-evolve
  - /evolve
  - improve harness
  - review my skills
  - update claude setup
  - what's not working
---

# Self-Evolve — Harness Improvement Loop

> Inspired by: NousResearch/hermes-agent (GEPA skill optimization pattern)
> Principle: The harness should get better from use, not just from manual edits.

Claude Code itself is the optimizer. You read session history, identify what isn't working,
and propose specific, reviewable changes. The human approves every edit.

---

## Phase 0: Gather Evidence

Read from three sources in parallel:

### 1. Session DB (primary signal)
```python
import sqlite3, pathlib
db = pathlib.Path.home() / ".claude/sessions/sessions.db"
# Query: what tasks failed? what tools were used most? what patterns repeat?
```

If session DB doesn't exist: note it and rely on sources 2 and 3.

### 2. Feedback memories
Read all `type: feedback` files from `~/.claude/projects/*/memory/` and
`~/.claude/projects/C--Users-heiwa/memory/`.

### 3. Session log files
Read the 20 most recent session logs from `~/.claude/sessions/*.md`.
Extract: task descriptions, tools used, any failure patterns.

---

## Phase 1: Pattern Analysis

Identify one or more of these patterns:

| Pattern | Evidence | What to update |
|---------|----------|----------------|
| Skill triggered but wrong | Session logs show skill loaded for unrelated task | Routing table trigger keywords |
| Task needed multiple retries | Session has same tool called 3+ times | Add guidance to relevant SKILL.md |
| Feedback correction repeated | Same feedback saved twice | CLAUDE.md or skill anti-pattern list |
| Skill route missing | User asked for X, no skill triggered | Add routing table entry |
| Context blew up | Sessions > 50K tokens regularly | Add compaction guidance to relevant skill |
| Memory saved wrong tier | Project memory in global, or vice versa | Update memory-protocol.md |

Report findings as: "Pattern X found N times. Proposed change: [specific edit]."

---

## Phase 2: Propose Changes

For each pattern, produce a specific diff-style proposal:

```
FILE: ~/.claude/CLAUDE.md
CHANGE: In routing table, change CSS/UI row to add "frontend" as trigger
CURRENT:  | CSS / UI work | `frontend-design` skill ...
PROPOSED: | CSS / UI / frontend work | `frontend-design` skill ...
REASON: 3 sessions where user said "frontend" but skill wasn't triggered
```

Rules for proposals:
- One change per pattern — don't batch unrelated edits
- Always quote the CURRENT text and the PROPOSED replacement
- Always state evidence count ("found in N sessions")
- Never propose changes to memory files (those reflect real history)
- Prefer routing table tweaks over SKILL.md rewrites
- Never propose changes to security scripts (bash-guard, scan-secrets)

---

## Phase 3: Human Review

Present all proposals together. For each:
- Show file, current text, proposed text, evidence count
- Ask: "Apply this change? [yes/no/modify]"

Do NOT apply any change until user says yes.

---

## Phase 4: Apply Approved Changes

For each approved change:
1. Edit the file (use Edit tool, not Write — preserve surrounding context)
2. Print confirmation: `[APPLIED] file: line`
3. If change is to `config/CLAUDE.md` or a skill in `claude-setup/`: also apply to repo file

After all changes applied, offer to run `/self-evolve` again in 2 weeks to measure impact.

---

## Phase 5: Commit (Optional)

If any changes were applied to the `claude-setup` repo files:
```
git add -A
git commit -m "chore: harness self-evolution — [brief summary of what changed]"
git push origin main
```

Ask user before pushing.

---

## What Self-Evolution Does NOT Do

- Does NOT autonomously modify files without showing diffs first
- Does NOT touch memory files (those are historical record)
- Does NOT modify security scripts
- Does NOT run any training loop or optimization algorithm
- Does NOT require external dependencies (DSPy, etc.) — uses session logs directly
- Does NOT push to GitHub without explicit user approval

The improvement is: **session logs → pattern detection → proposed edits → human approval → applied**.
This is the hermes-agent GEPA spirit, implemented natively in Claude Code's tools.
