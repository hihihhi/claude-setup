# Claude Code Setup — Usage Guide

How to get the most out of this installation. Everything here is about *what to say* to trigger the right behavior.

---

## 1. Role Overlays — Set Your Context First

Start every new session by activating a role. This wires up phase routing, preferred skills, and agent preferences automatically.

```
load role developer
load role researcher
load role designer
load role product
load role devops
load role data-scientist
```

**Why it matters:** Without a role, Claude uses general defaults. With `load role developer`, it automatically routes "add a feature" through the full dev workflow (plan → TDD → implement → review → PR), not just inline edits.

---

## 2. Phase Routing — Say These Exact Phrases

These trigger words activate specific skill workflows:

| What you say | What happens |
|---|---|
| `"new project"` / `"build X from scratch"` | Phase 0: scaffold, architecture design, file structure |
| `"new feature"` / `"implement X"` | Phase 2: plan → failing tests → implement → review |
| Any error or stack trace | `/investigate`: reproduce → isolate → hypothesize → fix |
| `"refactor X"` | Code review first, then surgical refactor without behavior change |
| `"test this"` / `"add tests"` / `"QA"` | TDD workflow or test suite generation |
| `"review this"` / `"PR ready"` | Full code review: correctness, security, performance, maintainability |
| `"ship"` / `"deploy"` / `"create PR"` | Commit with conventional message → PR with summary |
| `"research X"` | 5-stage deep research pipeline with source tracking |
| `"plan X"` | Implementation plan with vertical slices and acceptance criteria |
| `"checkpoint"` / `"save state"` | Writes current progress to session state file |
| `"where were we"` / `"resume"` | Reads state file and resumes from last checkpoint |

---

## 3. Explicit Skill Invocation

Call skills directly with `/skill-name` in Copilot Chat or `use the <skill> skill` in Claude Code:

### Development workflow
- `/tdd` — write failing tests first, then implement to make them pass
- `/code-review` — structured review with [CRITICAL/HIGH/MEDIUM/LOW] severity ratings
- `/security-review` — OWASP Top 10 audit on selected code
- `/commit` — generate conventional commit message from staged diff
- `/create-pr` — create PR with summary, test plan, and change rationale
- `/refactor` — improve structure without changing behavior, flags unrelated issues separately
- `/systematic-debugging` — reproduce → isolate → hypothesize → fix → verify loop

### Research and planning
- `/deep-research` — 5-stage research with anti-sycophancy guards and source ledger
- `/prd-to-plan` — convert requirements doc into vertical implementation slices
- `/write-a-prd` — generate a product requirements document from a description
- `/brainstorming` — structured ideation with constraint-first thinking

### Architecture
- `/improve-codebase-architecture` — analyze and propose structural improvements
- `/ubiquitous-language` — define domain terminology for consistency across codebase
- `/executing-plans` — run through a multi-step implementation plan with checkpoints

### Git
- `/using-git-worktrees` — set up parallel workstreams without branch switching
- `/finishing-a-development-branch` — checklist before merging: tests, review, changelog
- `/git-guardrails-claude-code` — protect main branch, enforce conventional commits

---

## 4. Agent Orchestration — When to Use Multi-Agent Mode

Say these to switch modes:

```
use team mode         # 2-4 files, 1-3 hour tasks — spawns Architect + Implementer + Reviewer
use fleet mode        # multi-day features — full agent pipeline with context isolation
run in parallel       # two independent subtasks — spawns both agents simultaneously
```

**Key rule:** Generator ≠ Evaluator. Always say `have a separate agent review this` after any significant implementation. The same agent that wrote it cannot review it objectively.

**Model hints:**
- `use opus for this` — architecture decisions, complex design tradeoffs
- `use haiku to explore` — fast file browsing, search, orientation tasks
- `use sonnet to implement` — default implementation (already the default)

**150+ agents are installed.** To invoke one by category:
```
use the security engineer agent
use the database optimizer agent
use the frontend developer agent
use the backend architect agent
```

---

## 5. Memory — What to Store, How to Retrieve

The memory system has three tiers. You control Tier 2 (project memory).

### Saving to memory
```
remember that we use pnpm in this project
remember that tests hit a real database, no mocks
remember that Oscar prefers one bundled PR over many small ones
```

### Recalling memory
```
what do you remember about this project?
check your memory before suggesting a testing approach
```

### What's worth saving
- Project-specific decisions that aren't in the code (e.g., "we're on a merge freeze until April 15")
- Preferences that would otherwise need to be re-explained each session
- References to external systems ("bugs tracked in Linear project IGSL")
- Feedback on approaches that worked or didn't

### What NOT to save
- Code patterns (read the code instead)
- Architecture that's visible in the repo
- Debugging solutions (those belong in commit messages)

---

## 6. The Karpathy Rules — Built into Every Response

The `karpathy-guidelines` skill is always active. It enforces four principles that directly affect what you should ask for:

**Think Before Coding** — always say what you want *before* asking for code. `"I need X because Y"` gets better results than `"write X"`. Claude will state assumptions before starting.

**Simplicity First** — ask for the simplest thing that works. Don't ask for "a robust, scalable, extensible solution" — ask for the minimum that solves the problem. You can always extend.

**Surgical Changes** — ask for changes scoped to the minimum necessary. `"fix the null check on line 47"` is better than `"improve the error handling in this file"`.

**Goal-Driven Execution** — tell Claude *what success looks like*, not just *what to do*. `"make the test pass"` or `"the user should be able to log in without a refresh"` keeps it focused.

---

## 7. Security Hooks — What Gets Blocked

Two hooks silently protect you:

**`bash-guard.py`** blocks shell commands matching dangerous patterns:
- `rm -rf` with sensitive paths
- `curl ... | bash` (script injection)
- `chmod 777`
- Piping to shell from untrusted sources

If a bash command gets blocked, Claude will tell you what triggered it and suggest a safer alternative.

**`scan-secrets.py`** blocks file writes containing:
- API keys matching known patterns (`sk-`, `ghp_`, `AKIA*`)
- Tokens and passwords in plain text

If a write gets blocked, Claude will suggest using environment variables instead.

---

## 8. Deep Research — Getting the 5-Stage Pipeline

When researching any topic, say:
```
research X using the deep-research skill
```

Or for quick vs thorough:
```
flash research on X      # 1 search, headline findings only
standard research on X   # 3 sources, main conclusions
deep research on X       # 5-stage pipeline, full source ledger, confidence ratings
```

The IRON RULE is always in effect: **the core question from Stage 1 governs the entire session**. If you want to change the research direction mid-session, say `"new research question: ..."` to reset the anchor explicitly.

Anti-sycophancy is built in — if Claude agrees with you 3 times in a row without finding a counterpoint, it will flag this and search harder for contrary evidence.

---

## 9. Context Management

The setup keeps context efficient automatically, but you can help:

```
compact context now           # force compression of conversation history
context reset                 # start fresh while keeping memory (better than compacting)
use a sub-agent for this      # isolates a task so its output doesn't pollute your context
```

For large tasks, say: `"run this as a background agent and report back"` — this keeps your main session clean.

**When to reset vs compact:** Reset when switching between unrelated tasks. Compact when continuing the same task that's gotten long. Never compact when output quality has degraded — reset instead.

---

## 10. VS Code / Copilot Integration

If you use VS Code with the Copilot extension alongside Claude Code:

- `.vscode/settings.json` is pre-configured with instruction injection for code generation, test generation, review, and commit messages.
- Path-scoped instruction files in `.github/instructions/` activate automatically when you open matching file types.
- Prompt files in `.github/prompts/` are invocable with `/name` in Copilot Chat.

---

## Quick Reference Card

```
# Start session
load role developer

# Plan a feature
plan: add OAuth login to the API

# Implement with TDD
implement the login endpoint using TDD

# Review before PR
have a separate agent review the auth changes

# Ship
create a PR for the oauth-login branch

# Research something
deep research on passkey authentication patterns 2024

# Debug
[paste error/stack trace]

# Checkpoint
checkpoint: completed oauth login, starting on token refresh

# Resume next day
where were we?
```
