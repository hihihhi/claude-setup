#!/usr/bin/env python3
"""
init-memory.py — Seeds the MCP knowledge graph with an initial set of entities.

Run once after install to populate Tier 3 memory with:
  - This installation's configuration (OS, tools, paths)
  - Core concept entities (Claude Code architecture, hook system)
  - Starter relations between them

The MCP memory server reads entities.jsonl. Each line is a JSON record with
type "entity" or "relation". This script writes the initial seed records.

Usage:
    python3 init-memory.py                    # use default ~/.claude/memory/entities.jsonl
    python3 init-memory.py --file /path/to/entities.jsonl
"""

import json
import os
import platform
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# ── Helpers ───────────────────────────────────────────────────────────────────

def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

def tool_version(cmd: str) -> str:
    try:
        out = subprocess.check_output([cmd, "--version"], text=True, stderr=subprocess.STDOUT)
        return out.strip().split("\n")[0]
    except Exception:
        return "unknown"

def which(cmd: str) -> str:
    import shutil
    return shutil.which(cmd) or "not found"

def make_entity(name: str, entity_type: str, observations: list[str]) -> dict:
    return {
        "type": "entity",
        "name": name,
        "entityType": entity_type,
        "observations": observations,
    }

def make_relation(from_name: str, relation: str, to_name: str) -> dict:
    return {
        "type": "relation",
        "from": from_name,
        "relationType": relation,
        "to": to_name,
    }

# ── Build seed data ───────────────────────────────────────────────────────────

def build_seed_entities() -> list[dict]:
    os_name = platform.system()
    node_v = tool_version("node")
    python_v = tool_version("python3") or tool_version("python")
    git_v = tool_version("git")
    claude_v = tool_version("claude")
    uv_v = tool_version("uv")
    jq_v = tool_version("jq")
    claude_home = os.path.expanduser("~/.claude")

    entities = [
        # ── Installation record ──────────────────────────────────────────────
        make_entity(
            name="claude-setup-installation",
            entity_type="Installation",
            observations=[
                f"Installed on {now_iso()}",
                f"OS: {os_name} ({platform.release()})",
                f"CLAUDE_HOME: {claude_home}",
                f"node version: {node_v}",
                f"python version: {python_v}",
                f"git version: {git_v}",
                f"claude CLI: {claude_v}",
                f"uv: {uv_v}",
                f"jq: {jq_v}",
                "Repo: https://github.com/hihihhi/claude-setup",
            ],
        ),

        # ── Claude Code architecture ─────────────────────────────────────────
        make_entity(
            name="Claude Code",
            entity_type="Tool",
            observations=[
                "Anthropic's official CLI for agentic coding assistance",
                "Installed via: npm install -g @anthropic-ai/claude-code",
                "Config lives in ~/.claude/ (CLAUDE.md, settings.json, skills/, agents/)",
                "Skills are markdown files in ~/.claude/skills/<name>/SKILL.md",
                "Agents are markdown files in ~/.claude/agents/<name>.md",
                "Settings in ~/.claude/settings.json control MCP servers, hooks, statusLine",
                "Memory system: Tier 1 (CLAUDE.md), Tier 2 (project memory/*.md), "
                "Tier 3 (MCP knowledge graph at ~/.claude/memory/entities.jsonl)",
            ],
        ),

        # ── Hook system ──────────────────────────────────────────────────────
        make_entity(
            name="Hook System",
            entity_type="Architecture",
            observations=[
                "Hooks are shell commands that intercept Claude Code's tool use lifecycle",
                "UserPromptSubmit: fires before each prompt — memory-search.py injects top 3 memory files",
                "PreToolUse:Bash: bash-guard.py — blocks dangerous commands (rm -rf, curl | sh, etc.)",
                "PreToolUse:Write|Edit: scan-secrets.py — blocks hardcoded API keys/tokens",
                "Stop: update-state.py — writes session summary to project state.md",
                "SessionStart: reads project state.md to restore context",
                "Hook allow/deny: empty stdout = allow; JSON with permissionDecision = deny",
                "Configured in ~/.claude/settings.json under 'hooks' key",
            ],
        ),

        # ── Memory system ────────────────────────────────────────────────────
        make_entity(
            name="Memory System",
            entity_type="Architecture",
            observations=[
                "Tier 1 (always loaded): ~/.claude/CLAUDE.md + ~/.claude/rules/*.md",
                "Tier 2 (per-project, TF-IDF): ~/.claude/projects/<hash>/memory/*.md",
                "Tier 2 injection: UserPromptSubmit hook runs memory-search.py, "
                "scores files with TF-IDF, injects top 3 matches into context",
                "Tier 3 (cross-project): MCP memory server reading entities.jsonl",
                "Tier 3 queries: search_nodes('topic') or read_graph() tool calls",
                "Project hash format: C--Users-username-path-to-project (drive+path, dashes)",
                "Save to Tier 2: Write .md files to ~/.claude/projects/<hash>/memory/",
                "Save to Tier 3: Use mcp__memory__create_entities or mcp__memory__create_relations",
            ],
        ),

        # ── TF-IDF memory hook ───────────────────────────────────────────────
        make_entity(
            name="TF-IDF Memory Hook",
            entity_type="Script",
            observations=[
                "File: ~/.claude/scripts/memory-search.py",
                "Triggered by: UserPromptSubmit hook on every prompt",
                "Reads all .md files in the current project's memory directory",
                "Scores each file against the current prompt using TF-IDF cosine similarity",
                "Injects the top 3 matching files as context into Claude's prompt",
                "To add project-specific memory: "
                "write .md files to ~/.claude/projects/<hash>/memory/",
            ],
        ),

        # ── Security hooks ───────────────────────────────────────────────────
        make_entity(
            name="Security Hooks",
            entity_type="Script",
            observations=[
                "bash-guard.py: blocks dangerous bash commands via regex",
                "Blocked patterns: rm -rf /, fork bombs, curl|sh pipe execution, "
                "format drives (mkfs), wipe commands (dd if=/dev/zero), "
                "global sudo pip install, chmod 777 /, kill all processes",
                "scan-secrets.py: blocks writing hardcoded API keys/tokens to files",
                "Detected patterns: AWS keys (AKIA...), GitHub tokens (ghp_...), "
                "generic API_KEY = '...', JWT secrets, private key blocks",
                "Both scripts: empty stdout = allow; JSON deny response = block",
            ],
        ),

        # ── Copilot setup companion ──────────────────────────────────────────
        make_entity(
            name="copilot-setup",
            entity_type="Project",
            observations=[
                "Companion repo for GitHub Copilot configuration",
                "Repo: https://github.com/hihihhi/copilot-setup",
                "Zero dependencies — pure file copy, works air-gapped",
                "Key files: .github/copilot-instructions.md (behavioral contract), "
                ".github/instructions/*.instructions.md (path-scoped), "
                ".github/prompts/*.prompt.md (slash commands)",
                "11 prompts: plan, scaffold, explain, commit, tdd, code-review, "
                "security-review, debug, refactor, deep-research, prd-to-plan",
                "Manual install: copy .github/ and .vscode/ into target project",
                "See MANUAL-INSTALL.md for air-gapped installation guide",
            ],
        ),
    ]

    return entities


def build_seed_relations() -> list[dict]:
    return [
        make_relation("claude-setup-installation", "installs", "Claude Code"),
        make_relation("claude-setup-installation", "configures", "Hook System"),
        make_relation("claude-setup-installation", "configures", "Memory System"),
        make_relation("Hook System",  "implements", "TF-IDF Memory Hook"),
        make_relation("Hook System",  "implements", "Security Hooks"),
        make_relation("Memory System", "uses",      "TF-IDF Memory Hook"),
        make_relation("Claude Code",  "companion-to", "copilot-setup"),
    ]


# ── Write to entities.jsonl ───────────────────────────────────────────────────

def main() -> None:
    # Resolve output path
    if len(sys.argv) >= 3 and sys.argv[1] == "--file":
        entities_file = Path(sys.argv[2])
    else:
        entities_file = Path.home() / ".claude" / "memory" / "entities.jsonl"

    entities_file.parent.mkdir(parents=True, exist_ok=True)

    # Read existing records to avoid duplicates
    existing_names: set[str] = set()
    existing_relations: set[tuple] = set()

    if entities_file.exists():
        for line in entities_file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
                if rec.get("type") == "entity":
                    existing_names.add(rec.get("name", ""))
                elif rec.get("type") == "relation":
                    existing_relations.add((rec.get("from"), rec.get("relationType"), rec.get("to")))
            except json.JSONDecodeError:
                pass

    # Build new records
    entities = build_seed_entities()
    relations = build_seed_relations()

    new_entities = [e for e in entities if e["name"] not in existing_names]
    new_relations = [
        r for r in relations
        if (r["from"], r["relationType"], r["to"]) not in existing_relations
    ]

    if not new_entities and not new_relations:
        print("Memory already seeded — nothing to add.")
        return

    # Append to file
    with entities_file.open("a", encoding="utf-8") as f:
        for record in new_entities + new_relations:
            f.write(json.dumps(record) + "\n")

    print(f"Seeded {len(new_entities)} entities and {len(new_relations)} relations "
          f"into {entities_file}")


if __name__ == "__main__":
    main()
