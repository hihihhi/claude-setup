# Harness Engineering Principles
> Always-loaded. Source: shareAI-lab/learn-claude-code, Harness = Agent − Model.

1. **CLAUDE.md = navigation index** — standing rules only, no transient state, < 200 lines / 5K tokens
2. **Context budget** — CLAUDE.md + rules/ + MEMORY.md index must stay under 5K tokens always-loaded; everything else loads on demand
3. **Skills load on demand** — routing table triggers them; never pre-load all skills
4. **Rules load always** — this file is why rules/ must stay minimal and evergreen
5. **Generator ≠ Evaluator** — the agent that writes code never reviews it; always a separate sub-agent
6. **Iterate until complete** — work autonomously through all steps; verify each; no mid-task check-ins
7. **Sub-agents as context firewalls** — spawn a sub-agent for long tasks rather than accumulating context inline
8. **Three-tier memory** — CLAUDE.md (rules) → project memory files (facts) → MCP knowledge graph (cross-project)
9. **Compact at task boundaries** — not mid-task, not on timers; trigger manually or at context threshold
10. **Idempotent everything** — running setup twice must not break anything; check before creating

## Context Compaction (4-Lever Strategy from learn-claude-code/s06)

Apply in order when context grows large:

| Lever | When | Action |
|-------|------|--------|
| 0 Persist Output | Tool output > 50KB | Write to disk, replace with `<persisted-output: path>` marker |
| 1 Micro-Compact | Old tool results > 3 turns back | Replace with `<result: summary>` placeholder, keep file reads |
| 2 Auto-Compact | Context > ~50K tokens | Summarize full transcript, save to disk with FTS5 index, inject continuation |
| 3 Manual Compact | Task boundary | Agent-triggered: summarize current state, clear old turns, rehydrate key files |

**Rule:** Compaction relocates detail — never deletes lineage. Save transcripts to disk so they can be retrieved.

## Hook Exit Codes (from learn-claude-code/s08)

| Exit | Meaning | Used in |
|------|---------|---------|
| 0 | Allow silently | PreToolUse, PostToolUse |
| 1 | Block + return stderr as error | PreToolUse only |
| 2 | Inject stderr as context message, tool still runs | Both |

**Most valuable hooks to write:**
- `PreToolUse` on `Bash` — security scanning, dangerous command detection
- `PreToolUse` on `Write/Edit` — secret scanning, lint check
- `PostToolUse` on `Write/Edit` — auto-format (prettier, ruff)
- `Stop` — state snapshot, session summary to disk
