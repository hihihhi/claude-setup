# claude-setup

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-harness-8A2BE2)](https://docs.anthropic.com/en/docs/claude-code)
[![Platform](https://img.shields.io/badge/Platform-Win%20%7C%20Mac%20%7C%20Linux-lightgrey)]()

**One-click Claude Code harness for teams.** Installs a fully optimized Claude Code environment with research + dev pipelines, multi-agent teams, persistent memory, and skill auto-discovery.

---

## What This Does

Running `./install.sh` (or `./install.ps1` on Windows) sets up your `~/.claude/` directory with:

- **214+ skills** auto-loaded by context (181 via ECC plugin + 14 superpowers + 19 mattpocock)
- **150 agents** across 10 domains (engineering, design, marketing, sales, product, research, etc.)
- **5 hooks** for security, memory injection, state tracking, and session management
- **6 role overlays** so devs, researchers, designers, PMs, DevOps, and data scientists each get relevant tools
- **3 team templates** for multi-agent coordination (research, dev, full-pipeline)
- **3-tier memory system** that persists across sessions and projects

## Architecture

```
+-----------------------------------------------------------------------+
|                    UNIFIED CLAUDE CODE HARNESS                         |
+-----------------------------------------------------------------------+
|                                                                       |
|  Layer 0: Base           everything-claude-code (ECC)                 |
|                          181 skills + 47 agents + hooks + rules       |
|                                                                       |
|  Layer 1: Methodology    superpowers (14 skills: TDD, verification)   |
|                          mattpocock/skills (19: PRD-to-plan, grill-me)|
|                                                                       |
|  Layer 2: Research       last30days-skill (trend research)            |
|                          K-Dense scientific (134 domain skills)        |
|                          deer-flow (heavy research offloading)         |
|                                                                       |
|  Layer 3: Role Agents    agency-agents (150 agents, 10 domains)       |
|                                                                       |
|  Layer 4: Observability  claude-hud (context budget + status)         |
|                                                                       |
|  Layer 5: Memory         3-tier: global + project + knowledge graph   |
|                          Dynamic injection via TF-IDF keyword search  |
|                                                                       |
|  Layer 6: Custom         CLAUDE.md + role overlays + team templates   |
|                          + security hooks + helper scripts            |
+-----------------------------------------------------------------------+
```

## Quick Start

```bash
git clone https://github.com/hihihhi/claude-setup.git
cd claude-setup
./install.sh        # Mac/Linux/Git Bash
# or
./install.ps1       # Windows PowerShell
```

The installer will:
1. Detect your OS
2. Prompt you to select role(s)
3. Install each layer in order
4. Generate attribution and manifest
5. Run a smoke test

## Role Selection

| # | Role | Skills Focus | Agents |
|---|------|-------------|--------|
| 1 | Full-Stack Developer | TDD, code-review, security-review, build-error-resolver | Architect, Implementer, Tester, Reviewer |
| 2 | Backend Developer | API design, database, security, testing | Same as above |
| 3 | Frontend / Designer | Impeccable suite, shadcn-ui, frontend-patterns, WCAG AA | Designer, Frontend Reviewer |
| 4 | Researcher / Analyst | deep-research, last30days, market analysis, scientific | Researcher, Analyst, Reviewer |
| 5 | Product Manager | PRD-to-plan, grill-me, office-hours, feature-forge | Product Manager, Researcher |
| 6 | Data Scientist / ML | PyTorch, eval harness, HuggingFace, MLflow | ML Engineer, Data Analyst |
| 7 | DevOps / SRE | Docker, Terraform, CI/CD, monitoring, deploy | Infra Architect, SRE |
| 8 | All | Everything above | All agents |

Roles are additive -- pick multiple (e.g., `1,4` for Full-Stack + Researcher).

## What Gets Installed

### Skills & Agents

| Component | Count | Source | License |
|-----------|-------|--------|---------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 181 skills, 47 agents | Affaan Mustafa | MIT |
| [superpowers](https://github.com/obra/superpowers) | 14 skills | Jesse Vincent | MIT |
| [mattpocock/skills](https://github.com/mattpocock/skills) | 19 skills | Matt Pocock | MIT |
| [agency-agents](https://github.com/msitarzewski/agency-agents) | 150 agents | Maciej Sitarzewski | MIT |
| [impeccable](https://github.com/pbakaus/impeccable) | 21 skills | Paul Bakaus | Apache 2.0 |
| [claude-hud](https://github.com/jarrodwatts/claude-hud) | Status line | Jarrod Watts | MIT |
| [last30days-skill](https://github.com/mvanhorn/last30days-skill) | 1 skill | mvanhorn | MIT |
| [claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) | 134 skills | K-Dense AI | MIT |
| [deer-flow](https://github.com/bytedance/deer-flow) | Research agent | ByteDance | MIT |

### Helper Scripts

| Script | Hook | Purpose |
|--------|------|---------|
| `memory-search.py` | UserPromptSubmit | TF-IDF keyword search across all project memories, injects top 3 matches |
| `bash-guard.py` | PreToolUse (Bash) | Blocks `rm -rf /`, force push to main, `sudo rm`, pipe-to-shell, DROP TABLE, fork bombs |
| `scan-secrets.py` | PreToolUse (Write/Edit) | Detects API keys (sk-, AKIA, ghp_, glpat-), private keys, hardcoded passwords |
| `update-state.py` | Stop | Auto-updates `.claude/state.md` with timestamp and session summary |
| `health-check.sh` | Manual | Verifies all components installed, reports green/yellow/red per component |
| `sync-shared-memory.sh` | Manual/cron | Syncs team knowledge base via git |

### Hook System

Hooks use the current Claude Code response format:
- **Allow**: output nothing (empty stdout = proceed)
- **Deny**: output `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "..."}}`
- **Exit code 2**: hard block without JSON

## Memory System

Three-tier persistent memory across sessions and projects:

| Tier | Scope | Location | Loaded |
|------|-------|----------|--------|
| 1 | Global | `~/.claude/CLAUDE.md` + `rules/*.md` | Always (< 5K tokens) |
| 2 | Per-project | `~/.claude/projects/<proj>/memory/*.md` | On demand via TF-IDF hook |
| 3 | Cross-project | MCP memory server (knowledge graph) | On query |

The `UserPromptSubmit` hook runs `memory-search.py` on every message -- it extracts keywords, searches all project memory files using TF-IDF scoring, and injects the top 3 most relevant files into context. Runs in under 1 second across ~100 files.

## Multi-Agent Team Templates

### Research Team (`teams/templates/research-team.md`)
- **Opus lead** coordinates and synthesizes findings
- **4 Sonnet agents**: Researcher x2 (web + deep dive), Analyst, Reviewer (fact-check gate)
- Anti-sycophancy mechanisms, source citation requirements

### Dev Team (`teams/templates/dev-team.md`)
- **Opus architect** designs and plans
- **4 Sonnet agents**: Implementer x2 (worktree isolation), Tester (TDD), Reviewer (security)
- Generator != Evaluator: the agent that writes code never reviews it
- Max 400 lines per agent session

### Full Pipeline (`teams/templates/full-pipeline.md`)
- **Opus director** orchestrates Research -> Dev -> Quality
- **3 pods, 6 agents**: Research (researcher + analyst), Dev (implementer + tester), Quality (reviewer + security)
- 5 mandatory phase gates with structured handoff documents

## Security

All scripts use Python stdlib only (no external dependencies).

**bash-guard.py** blocks:
- `rm -rf /`, `rm -rf ~`, `rm -rf $HOME`
- `git push --force` to main/master
- `sudo rm`, `sudo dd`
- `curl | sh` (pipe to shell)
- `DROP TABLE`, `DROP DATABASE`
- `chmod 777`, fork bombs

**scan-secrets.py** detects:
- API keys: `sk-`, `pk_live_`, `AKIA`, `ghp_`, `gho_`, `glpat-`, `xoxb-`, `xoxp-`
- Private keys (RSA, EC, OPENSSH headers)
- Hardcoded passwords/secrets/tokens in assignments
- Database connection strings with embedded credentials
- Skips `.md` files and obvious fake/test values

## File Structure

```
claude-setup/
  install.sh              Bash installer (Mac/Linux/Git Bash)
  install.ps1             PowerShell installer (Windows)
  README.md
  LICENSE                 MIT
  ATTRIBUTION.md          All bundled components with licenses
  config/
    CLAUDE.md             Global navigation index (103 lines)
    roles/
      developer.md        Dev role overlay
      researcher.md       Research role overlay
      designer.md         Design role overlay
      product.md          PM role overlay
      devops.md           DevOps/SRE overlay
      data-scientist.md   ML/DS overlay
  scripts/
    memory-search.py      Dynamic memory injection
    bash-guard.py         Dangerous command blocker
    scan-secrets.py       Secret detection
    update-state.py       Auto state updater
    health-check.sh       Installation health check
    sync-shared-memory.sh Team knowledge sync
  teams/templates/
    research-team.md      Opus + 4 Sonnet research team
    dev-team.md           Opus + 4 Sonnet dev team
    full-pipeline.md      3-pod full pipeline
  docs/
    generate_report.py    PDF report generator
    Claude_Code_Harness_Report.pdf
```

## Attribution

This project bundles open-source components. See [ATTRIBUTION.md](./ATTRIBUTION.md) for the complete list.

**Not bundled** (license restrictions):
- [academic-research-skills](https://github.com/Imbad0202/academic-research-skills) -- CC BY-NC 4.0 (non-commercial only)
- andrej-karpathy-skills -- No license (patterns extracted, files not copied)

## Contributing

1. Fork and create a feature branch
2. Follow conventional commits (`feat:`, `fix:`, `chore:`, `docs:`)
3. No secrets or API keys in commits
4. Add attribution for any new bundled component
5. Submit PR with clear description

## License

[MIT](./LICENSE)
