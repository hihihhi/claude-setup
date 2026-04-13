# Team Claude Code — Global Instructions

## Identity & Approach
- Direct, concise. Lead with answer, not reasoning.
- No summaries of what you just did.
- No features/refactors/comments beyond what was asked.
- Prefer editing existing files. No speculative abstractions.
- **Iterate until complete**: for multi-step tasks, keep working through all steps autonomously — verify each step, fix errors, loop until done. Do not stop mid-task for unnecessary check-ins.

## When to Ask (Before Acting)
- **Ambiguous request** (2+ valid interpretations) → state both, ask which one. Never silently pick one.
- **Missing critical context** (which file? which function? what exact behavior?) → ask the single most important question. One question, not a list.
- **Scope unclear** (touches 1 file vs entire system) → state exactly what you'll change and confirm before starting.
- **Destructive or irreversible** (delete, drop, overwrite, push) → always confirm first.
- Once clarified, proceed without re-asking the same thing.

## Skill Auto-Discovery

| Context | Skills |
|---------|--------|
| Next.js project | `next-best-practices`, `next-cache-components` |
| React components | `vercel-react-best-practices`, `react-components` |
| TypeScript errors | `build-error-resolver` |
| PostgreSQL / DB | `supabase-postgres-best-practices`, `neon-postgres` |
| Auth | `better-auth-best-practices` |
| Stripe | `stripe-best-practices` |
| CSS / UI work | `frontend-design` skill (OKLCH color, anti-AI-slop, style directions); impeccable (`critique`, `colorize`, `typeset`, `polish`); `shadcn-ui` |
| Security audit | `insecure-defaults`, `security-review` |
| Git / PR | `commit`, `create-pr`, `code-review` |
| Testing | `webapp-testing`, `tdd` |
| Python | `modern-python` |
| Research / trends | `deep-research`, `last30days`, `market-news-analyst`, `karpathy-guidelines` |
| Quant / trading | `quant-research`, `backtest-expert`, `canslim-screener`, `vcp-screener`, `technical-analyst` |
| Econophysics / RL | `quant-research`, `deep-research`, `pytorch-patterns`, `backtest-expert` |
| Deployment | `deploy-to-vercel`, `netlify-cli-and-deploy` |
| Cloudflare | `wrangler`, `durable-objects`, `workers-best-practices` |
| Docker / infra | `docker-patterns`, `devcontainer-setup` |
| ML / AI | `pytorch-patterns`, `fal-ai-media`, `cost-aware-llm-pipeline` |
| Docs | `docx`, `pdf`, `pptx`, `xlsx` |

## Memory System
Three-tier: global -> project -> knowledge graph.

- **Tier 1 (Always)**: This file + `~/.claude/rules/*.md`
- **Tier 2 (Global default)**: `~/.claude/projects/C--Users-heiwa/memory/` — **save here by default**
  - Stores: preferences, feedback, workflow rules, coding standards, anything that applies across projects
- **Tier 2 (Project-specific)**: `~/.claude/projects/<proj>/memory/` — only for info tied to ONE project
  - Stores: project-specific bugs, one-off deadlines, repo-specific decisions
- **Tier 3 (Cross-project knowledge)**: MCP memory server (`knowledge-graph.json`)
  - Stores: deep domain knowledge, quant research vault, entities/relationships that span projects
  - Use for: the quant-research-vault papers, cross-project architectural patterns, domain expertise

**Default save location: `~/.claude/projects/C--Users-heiwa/memory/`**
Only use project-specific memory when the info ONLY makes sense for that one project.
Preferences, feedback, workflow rules, coding standards → always global (Tier 2 global).
Domain knowledge, research, cross-project entities → Tier 3 (MCP knowledge graph).

**Save**: user prefs, feedback, project context, references. Full protocol: `rules/memory-protocol.md`.
**Never save**: code/git derivable facts, current task progress, debugging recipes.
**Recall**: when relevant to current task or user asks. Tier 3: `search_nodes("topic")` or `read_graph()`.

## Multi-Agent Workflow

| Signal | Mode |
|--------|------|
| Quick fix, single file | In-session |
| 2-4 files, 1-3 hours | Team mode |
| Multi-day, large feature | Fleet mode |

- Generator != Evaluator. Reviewer is always separate from implementer.
- Haiku = exploration, Sonnet = implementation, Opus = architecture.
- Max 400 lines per sub-agent session.
- Context reset (not compaction) when output quality degrades.

## Phase Routing

| Trigger | Action |
|---------|--------|
| "new project" / "build X" | `/dev-workflow` Phase 0 |
| "new feature" / "implement X" | `/dev-workflow` Phase 2 |
| bug / error | `/investigate` |
| "ship" / "deploy" / "PR" | `/ship` |
| "test" / "QA" | `/qa` |
| "review code" | `/review` |
| research topic | `/deep-research` |
| trend analysis | `/last30days` |
| "plan" | `/plan` |
| "checkpoint" / "save state" | `/checkpoint` |
| "resume" / "where were we" | `/resume-session` |
| "improve harness" / "review skills" / "what's not working" | `/self-evolve` |

## Role Overlays
Activate with: `load role <name>` or auto-detected from project context.
Available: `developer`, `researcher`, `designer`, `product`, `devops`, `data-scientist`.
Roles add phase routing, priority skills, and preferred agents. See `config/roles/`.

## Context Budget
- This file: < 200 lines, < 5K tokens.
- Always-loaded total (CLAUDE.md + rules/ + MEMORY.md index): < 5K tokens.
- Skills load on demand via routing table. Rules load always — keep `rules/` minimal.
- Sub-agents as context firewalls for long tasks.
- **Compact at task boundaries** (not mid-task). See `rules/harness-principles.md` for 4-lever strategy.
- Hook exit codes: `0` = allow, `1` = block+error (PreToolUse only), `2` = inject+continue.

## Security (hard rules)
- Never hardcode secrets, tokens, API keys -- use env vars.
- Never hardcode URLs, hostnames, ports -- use config.
- Never log sensitive data.
- Sanitize user input before shell/SQL/HTML.

## Code Quality
- Max 100 char lines. Functions do one thing.
- No dead code, no commented-out code.
- Validate only at system boundaries.
- Conventional commits (`feat:`, `fix:`, `chore:`, `docs:`).

## Toolchain Defaults
- **Python**: `uv` if available, else `pip`. Formatter: `ruff`. Types: `pyright`.
- **TypeScript/JS**: `pnpm` if available, else `npm`. Formatter: `prettier`. Lint: `eslint`.
- **Git**: conventional commits. Reviewer sub-agent for all PRs.

## Windows Notes
- `npm` over `pnpm` for Windows-native dirs (symlink issues).
- Next.js builds: use WSL2 `npm` to avoid EINVAL readlink.
- Hooks run in bash -- use Unix paths always.
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
