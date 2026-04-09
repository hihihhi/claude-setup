# igsl-claude-setup

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-harness-8A2BE2)](https://docs.anthropic.com/en/docs/claude-code)
[![Teams](https://img.shields.io/badge/Teams-multi--agent-green)](./teams/templates/)

One-click Claude Code harness for teams -- research + dev pipelines, multi-agent teams, persistent memory, skill auto-discovery.

---

## Architecture

```
Layer 6: Team Templates          teams/templates/*.md
          Multi-agent coordination configs (research, dev, full-pipeline)

Layer 5: Memory System           3-tier: global -> project -> knowledge graph
          Persistent context across sessions and projects

Layer 4: Skills & Agents         ~/.claude/rules/*.md, agents/*.md
          200+ skills auto-loaded by context detection

Layer 3: Phase Routing           CLAUDE.md routing table
          Trigger -> action mapping (build, ship, test, review, research)

Layer 2: Role Overlays           config/roles/*.md
          developer, researcher, designer, product, devops, data-scientist

Layer 1: Global Config           config/CLAUDE.md
          Identity, security rules, code quality, toolchain defaults

Layer 0: Install Script          scripts/install.sh
          One-click setup, role selection, dependency resolution
```

## Quick Start

**One-liner install:**

```bash
curl -fsSL https://raw.githubusercontent.com/igsl/igsl-claude-setup/main/scripts/install.sh | bash
```

**Manual install:**

```bash
git clone https://github.com/igsl/igsl-claude-setup.git
cd igsl-claude-setup
bash scripts/install.sh
```

The installer will prompt you to select a role and configure your environment.

## Role Selection

| Role | Focus | Auto-loaded Skills | Best For |
|------|-------|--------------------|----------|
| `developer` | Full-stack implementation | next, react, shadcn-ui, tdd, code-review | Building features, fixing bugs |
| `researcher` | Investigation & analysis | deep-research, last30days, market-news | Market research, trend analysis |
| `designer` | UI/UX and frontend | impeccable suite, shadcn-ui, frontend-design | Design systems, component work |
| `product` | Planning & coordination | plan, office-hours, retro | Roadmap, specs, team coordination |
| `devops` | Infrastructure & deploy | docker-patterns, deploy-to-vercel, wrangler | CI/CD, cloud, containerization |
| `data-scientist` | ML & data analysis | pytorch-patterns, modern-python, backtest | Models, analysis, quantitative work |

Roles are additive overlays on the base config. Switch at any time with `load role <name>`.

## What Gets Installed

| Layer | Component | Source | Description |
|-------|-----------|--------|-------------|
| Config | Global CLAUDE.md | This repo | Base harness config: identity, security, routing |
| Config | Role overlays | This repo | Role-specific skill priorities and phase routing |
| Skills | everything-claude-code | [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 100+ workflow skills (tdd, ship, review, plan, etc.) |
| Skills | superpowers | [obra/superpowers](https://github.com/obra/superpowers) | Enhanced agent capabilities and tool patterns |
| Skills | mattpocock/skills | [mattpocock/skills](https://github.com/mattpocock/skills) | TypeScript-focused skills |
| Skills | agency-agents | [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) | Agent coordination patterns |
| Skills | impeccable | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | UI/UX review suite (critique, arrange, polish, typeset) |
| Skills | claude-hud | [jarrodwatts/claude-hud](https://github.com/jarrodwatts/claude-hud) | Session monitoring and status display |
| Skills | last30days-skill | [mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill) | Recent trend analysis and news |
| Skills | claude-scientific-skills | [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) | Scientific research and analysis |
| Orchestration | deer-flow | [bytedance/deer-flow](https://github.com/bytedance/deer-flow) | Multi-agent workflow orchestration |
| Teams | Team templates | This repo | Pre-built multi-agent team configs |

## Configuration

### Customizing CLAUDE.md

The base config lives at `config/CLAUDE.md`. After installation, it is symlinked or
copied to `~/.claude/CLAUDE.md`. To customize:

1. Edit `config/CLAUDE.md` in this repo.
2. Re-run `bash scripts/install.sh` to apply changes.

Key sections to customize:
- **Skill Auto-Discovery table**: Add rows for your project's tech stack.
- **Phase Routing table**: Map your team's commands to workflow phases.
- **Security rules**: Add project-specific security constraints.
- **Persistent Corrections**: Record mistakes to never repeat.

### Adding Skills

Skills are markdown files in `~/.claude/rules/` or loaded on demand via the routing
table.

```bash
# Install a community skill
claude skill install <skill-name>

# Create a custom skill
claude skill create my-skill
```

### Modifying Hooks

Hooks are configured in `~/.claude/settings.json`. They run bash commands before or
after specific Claude Code events.

```json
{
  "hooks": {
    "pre-commit": "bash scripts/pre-commit.sh",
    "post-session": "bash scripts/save-state.sh"
  }
}
```

## Team Templates

Pre-built multi-agent team configurations in `teams/templates/`:

### Research Team
**File**: [`teams/templates/research-team.md`](./teams/templates/research-team.md)

Opus lead + 4 Sonnet agents for deep investigation. Includes anti-sycophancy
reviewer gate, source citation requirements, and structured output format.

### Dev Team
**File**: [`teams/templates/dev-team.md`](./teams/templates/dev-team.md)

Opus architect + 4 Sonnet agents for parallel feature implementation. Includes
worktree isolation, TDD enforcement, 400-line limits, and Generator!=Evaluator
code review.

### Full Pipeline
**File**: [`teams/templates/full-pipeline.md`](./teams/templates/full-pipeline.md)

Opus director orchestrating Research, Dev, and Quality pods. Full lifecycle from
investigation through shipped code with mandatory phase gates.

### Creating Custom Teams

Copy any template and modify agent definitions, model assignments, and coordination
rules to fit your workflow:

```bash
cp teams/templates/dev-team.md teams/templates/my-team.md
# Edit agent roles, skills, and constraints
```

## Memory System

Three-tier persistent memory across sessions and projects.

### Tier 1: Global (Always Loaded)
- `~/.claude/CLAUDE.md` -- base config, always in context
- `~/.claude/rules/*.md` -- rule files, always in context

### Tier 2: Per-Project (Auto-loaded)
- `~/.claude/projects/<project>/memory/MEMORY.md` -- project-specific context
- Topic-specific files in the same directory
- `.claude/state.md` in each project root -- current task state, session results

### Tier 3: Knowledge Graph (Cross-Project)
- MCP memory server stores entities and relations in `knowledge-graph.json`
- Searchable across all projects
- Use `mcp__memory__create_entities` to save, `mcp__memory__search_nodes` to recall

### Memory Flow

```
User says something worth remembering
        |
        v
Save to Tier 2 (project memory)
        |
        v
Save to Tier 3 (knowledge graph)
        |
        v
Append to LEARNINGS.md if research-related
```

## Attribution

This project bundles open-source components under MIT and Apache 2.0 licenses.
See [ATTRIBUTION.md](./ATTRIBUTION.md) for the full list with copyright notices
and repository links.

Components **not bundled** due to license restrictions:
- `academic-research-skills` (CC BY-NC 4.0 -- non-commercial)
- `karpathy-skills` (no license file)

## Contributing

1. Fork the repo.
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make changes. Follow conventional commits (`feat:`, `fix:`, `chore:`, `docs:`).
4. Ensure no secrets, tokens, or API keys are committed.
5. Submit a pull request with a clear description of what changed and why.

### Adding a New Skill Source

1. Verify the source repo has an MIT, Apache 2.0, or similarly permissive license.
2. Add it to the install script in `scripts/install.sh`.
3. Add an entry to `ATTRIBUTION.md`.
4. Add routing entries to `config/CLAUDE.md` if the skill should auto-load.
5. Test the full install flow.

### Adding a New Team Template

1. Create a new file in `teams/templates/`.
2. Follow the structure of existing templates (team structure, agent definitions,
   coordination rules, phase flow, usage, when to use).
3. Document the template in this README under Team Templates.

## License

[MIT](./LICENSE)
