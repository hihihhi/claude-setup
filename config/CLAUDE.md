# Team Claude Code — Global Instructions

## Identity & Approach
- Direct, concise. Lead with answer, not reasoning.
- No summaries of what you just did.
- No features/refactors/comments beyond what was asked.
- Prefer editing existing files. No speculative abstractions.
- **Iterate until complete**: for multi-step tasks, keep working through all steps autonomously — verify each step, fix errors, loop until done. Do not stop mid-task for unnecessary check-ins.

## Skill Auto-Discovery

| Context | Skills |
|---------|--------|
| Next.js project | `next-best-practices`, `next-cache-components` |
| React components | `vercel-react-best-practices`, `react-components` |
| TypeScript errors | `build-error-resolver` |
| PostgreSQL / DB | `supabase-postgres-best-practices`, `neon-postgres` |
| Auth | `better-auth-best-practices` |
| Stripe | `stripe-best-practices` |
| CSS / UI work | `shadcn-ui`, impeccable suite (`critique`, `arrange`, `colorize`, `typeset`, `polish`) |
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

## When to Ask (Before Acting)
- **Ambiguous request** (2+ valid interpretations) → state both, ask which one. Never silently pick one.
- **Missing critical context** (which file? which function? what exact behavior?) → ask the single most important question. One question, not a list.
- **Scope unclear** (touches 1 file vs entire system) → state exactly what you'll change and confirm before starting.
- **Destructive or irreversible** (delete, drop, overwrite, push) → always confirm first.
- Once clarified, proceed without re-asking the same thing.

## Memory System
Three-tier: global preferences -> project-specific context -> cross-project knowledge.

- **Tier 1 (Always)**: This file + `~/.claude/rules/*.md`
- **Tier 2 Global (Default save)**: `~/.claude/projects/C--Users-heiwa/memory/` — **preferences, feedback, workflow rules; save here by default**
- **Tier 2 Project**: `~/.claude/projects/<proj>/memory/` — only for info tied to ONE specific project
- **Tier 3 (Deep knowledge)**: MCP memory server — domain knowledge, research vault, cross-project entities

**Tier 2 Global** (default — applies everywhere):
- User preferences and feedback corrections
- Workflow rules ("always use agent teams", "loop until criterion met")
- Coding standards that apply across all projects
- Anything you'd want to remember regardless of which repo you're in

**Tier 2 Project** (only when truly project-specific):
- A bug unique to that codebase
- A one-off deadline or stakeholder constraint
- A repo-specific architectural decision

**Tier 3 — Deep knowledge** (MCP knowledge graph):
- Domain knowledge (quant research vault, papers, strategies)
- Cross-project entities: technologies, patterns seen across multiple repos
- Relationships: "Project A uses same auth pattern as Project B"

**Never save**: code patterns derivable from reading the repo, git history, debugging recipes.

**Recall**: Tier 2 is automatic. Tier 3: `search_nodes("topic")` or `read_graph()`.

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

## Role Overlays
Activate with: `load role <name>` or auto-detected from project context.
Available: `developer`, `researcher`, `designer`, `product`, `devops`, `data-scientist`.
Roles add phase routing, priority skills, and preferred agents. See `config/roles/`.

## Context Budget
- This file: < 200 lines, < 5K tokens.
- Skills load on demand via routing table.
- Rules load always (keep minimal).
- Compact before switching tasks.
- Sub-agents as context firewalls.

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
