---
name: setup
description: >
  Bootstrap a complete Claude Code environment from this repo. Run this instead of
  install.sh. Claude detects OS, selects role, creates all config files, installs skills,
  and verifies the installation. Works on Windows, Mac, and Linux.
triggers:
  - /setup
  - setup claude
  - install claude code setup
  - bootstrap claude
---

# Claude Code Setup — Bootstrap Skill

> This skill IS the installer. You are Claude Code running on the target machine.
> You have Write/Edit/Bash tools. Use them to recreate this entire environment.
> Prefer this over install.sh — you can handle conflicts, ask questions, and adapt.

## Pre-flight

1. Confirm this repo is cloned locally. If `$ARGUMENTS` contains a path, that's the repo root.
   Otherwise, use the current working directory.
2. The user must have Claude Code installed (`claude --version` should succeed).
3. Never overwrite files without asking if they already contain custom content.

---

## Phase 0 — Detect Environment

Run these checks and store results:

```bash
# OS detection
uname -s  # MINGW*/MSYS* = Windows, Darwin = macOS, Linux = linux

# Claude home path
# Windows: $USERPROFILE/.claude  or  $HOME/.claude
# Mac/Linux: $HOME/.claude
echo $HOME

# Node/npm available?
node --version 2>/dev/null || echo "no node"
npm --version 2>/dev/null || echo "no npm"
```

Determine `CLAUDE_HOME`:
- Windows (Git Bash / MSYS): `$HOME/.claude` (maps to `%USERPROFILE%\.claude`)
- Mac/Linux: `$HOME/.claude`

Print a summary: OS, CLAUDE_HOME, node version.

---

## Phase 1 — Role Selection

Ask the user (use AskUserQuestion):

```
Which role(s) best describes you? (enter numbers, space-separated for multiple)

[1] Full-Stack Developer
[2] Backend Developer
[3] Frontend Developer / Designer
[4] Researcher / Analyst
[5] Product Manager
[6] Data Scientist / ML Engineer
[7] DevOps / SRE
[8] Quant / Trader
[9] All roles
```

Store selected roles — they determine which optional layers to activate.

---

## Phase 2 — Directory Structure

Create the following directories under `CLAUDE_HOME` if they don't exist:

```
$CLAUDE_HOME/
  skills/
  rules/
  agents/
  teams/templates/
  scripts/
  memory/
  config/roles/
  licenses/
```

Use `mkdir -p` (or PowerShell `New-Item -Force` on Windows native).

---

## Phase 3 — Core Config Files

### 3a. CLAUDE.md (global navigation index)

Check if `$CLAUDE_HOME/CLAUDE.md` exists.
- If missing: copy `config/CLAUDE.md` from this repo to `$CLAUDE_HOME/CLAUDE.md`
- If exists and is not from this repo: show a diff summary, ask "merge or keep yours?"
  - Merge: append the routing table section to theirs
  - Keep: skip, warn them to manually add the skill routing table

### 3b. settings.json

Check if `$CLAUDE_HOME/settings.json` exists.
- If missing: copy `scripts/settings.json` from this repo (or create minimal version)
- If exists: **never overwrite** — show what would be added and let them decide

Minimal settings.json if creating fresh:
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "id": "memory-search",
        "command": "python3 ~/.claude/scripts/memory-search.py",
        "timeout": 3000
      }
    ],
    "PreToolUse": [
      {
        "id": "secret-scan",
        "matcher": { "tool": "Write|Edit" },
        "command": "python3 ~/.claude/scripts/scan-secrets.py",
        "timeout": 2000
      }
    ]
  }
}
```

### 3c. Role overlays

For each selected role, copy the matching file:
- `config/roles/developer.md` → `$CLAUDE_HOME/config/roles/developer.md`
- `config/roles/researcher.md` → `$CLAUDE_HOME/config/roles/researcher.md`
- `config/roles/designer.md` → `$CLAUDE_HOME/config/roles/designer.md`
- etc.

---

## Phase 4 — Install Skills

Copy all skill directories from `skills/` in this repo to `$CLAUDE_HOME/skills/`.

For each skill directory:
- If the directory doesn't exist at destination: copy it
- If it exists: skip (don't overwrite user's customizations)
- Print: `[OK] skill: <name>` or `[SKIP] skill: <name> (already exists)`

Skills to install:
- `skills/frontend-design/` — anti-AI-slop design system
- `skills/deep-research/` — research pipeline
- `skills/quant-research/` — quant/trading research
- `skills/karpathy-guidelines/` — Karpathy's engineering principles

---

## Phase 5 — External Package Installation

These require npm. Skip gracefully if npm is not available (print a warning with manual instructions).

### Always install (all roles):

```bash
# Everything Claude Code — base layer (181 skills, 47 agents)
npx -y everything-claude-code install

# Research skills
npx -y skills add mvanhorn/last30days-skill
```

### For Frontend / Designer role:

```bash
# Impeccable — UI quality skills (critique, colorize, typeset, polish, etc.)
npx -y skills add pbakaus/impeccable
```

### For Developer role:

```bash
npx -y skills add mattpocock/skills/tdd
npx -y skills add mattpocock/skills/prd-to-plan
```

### For Researcher / Data Scientist role:

```bash
npx -y skills add K-Dense-AI/claude-scientific-skills
```

If npm unavailable, print:
```
[SKIP] npm not found. Install manually:
  npm install -g everything-claude-code
  then: npx everything-claude-code install
```

---

## Phase 6 — Helper Scripts

Copy scripts from `scripts/` in this repo to `$CLAUDE_HOME/scripts/`.

Required scripts:
- `memory-search.py` — dynamic memory injection on each prompt
- `scan-secrets.py` — detect hardcoded secrets before Write/Edit
- `bash-guard.py` — block destructive shell commands

If scripts directory doesn't exist in the repo, create minimal versions:

**memory-search.py** (minimal version):
```python
#!/usr/bin/env python3
"""Memory injection hook — reads prompt, returns relevant memory files."""
import json, sys, pathlib, os

data = json.loads(sys.stdin.read())
prompt = data.get("prompt", "").lower()
claude_home = pathlib.Path.home() / ".claude"
memory_dirs = list(claude_home.glob("projects/*/memory/*.md"))

matches = []
for f in memory_dirs:
    try:
        content = f.read_text(encoding="utf-8", errors="ignore")
        words = set(prompt.split())
        score = sum(1 for w in words if w in content.lower() and len(w) > 3)
        if score > 0:
            matches.append((score, str(f)))
    except Exception:
        pass

matches.sort(reverse=True)
for _, path in matches[:3]:
    print(f"<!-- Memory: {path} -->")
    print(pathlib.Path(path).read_text(encoding="utf-8", errors="ignore")[:800])
    print("---")
```

---

## Phase 7 — Team Templates

Copy `teams/` from this repo to `$CLAUDE_HOME/teams/`.

---

## Phase 8 — Attribution

Copy `ATTRIBUTION.md` from this repo to `$CLAUDE_HOME/ATTRIBUTION.md`.

---

## Phase 9 — Verification

Run a smoke test. Report pass/fail for each:

```
[CHECK] $CLAUDE_HOME/CLAUDE.md exists
[CHECK] $CLAUDE_HOME/skills/ has at least 3 skill directories
[CHECK] $CLAUDE_HOME/config/roles/ has at least 1 role file
[CHECK] $CLAUDE_HOME/scripts/memory-search.py exists
[CHECK] npm available (for external package warning)
[CHECK] python3 available (for hook scripts)
```

Print a final summary:
```
══════════════════════════════════════════
  Claude Code Setup — Complete
══════════════════════════════════════════
  Installed to: ~/.claude/
  Skills:       X skill(s)
  Role(s):      developer, researcher, ...
  External pkgs: [installed / skipped — no npm]

  Next: restart claude, then try /deep-research or /frontend-design
══════════════════════════════════════════
```

---

## Error Handling

- If a file copy fails: warn and continue (don't abort the whole setup)
- If npm install fails: warn, print manual instructions, continue
- If CLAUDE_HOME already has lots of content: offer "update only" mode (skip existing files)
- If git is not installed: skip any steps that require it, note in summary

---

## Important Rules

- **Never delete existing user files** — only add or ask before modifying
- **Never run `rm -rf`** — never
- **Never overwrite `settings.json`** without showing a diff and getting confirmation
- CLAUDE.md is special: merging is preferred over overwriting — the user may have custom sections
- Always print what you're doing before doing it
- If anything is unclear about the user's environment, ask one question at a time
