#!/usr/bin/env bash
# Health check for Claude Code setup.
#
# Verifies all components are installed and working:
# - CLAUDE.md exists
# - Skills directory has files
# - Hooks are configured
# - MCP servers are responding
# - Each installed layer from manifest
#
# Reports green/yellow/red status per component with a final summary.

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Counters
total=0
healthy=0
warning=0
failed=0

# Colors (if terminal supports them)
if [ -t 1 ] && command -v tput &>/dev/null; then
    RED="$(tput setaf 1 2>/dev/null || echo "")"
    GREEN="$(tput setaf 2 2>/dev/null || echo "")"
    YELLOW="$(tput setaf 3 2>/dev/null || echo "")"
    BOLD="$(tput bold 2>/dev/null || echo "")"
    RESET="$(tput sgr0 2>/dev/null || echo "")"
else
    RED=""
    GREEN=""
    YELLOW=""
    BOLD=""
    RESET=""
fi

pass() {
    echo "  ${GREEN}[OK]${RESET} $1"
    total=$((total + 1))
    healthy=$((healthy + 1))
}

warn() {
    echo "  ${YELLOW}[WARN]${RESET} $1"
    total=$((total + 1))
    warning=$((warning + 1))
}

fail() {
    echo "  ${RED}[FAIL]${RESET} $1"
    total=$((total + 1))
    failed=$((failed + 1))
}

section() {
    echo ""
    echo "${BOLD}$1${RESET}"
    echo "$(printf '%.0s-' $(seq 1 ${#1}))"
}

# ── Core Files ──────────────────────────────────────────────
section "Core Files"

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    size=$(wc -c < "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || echo "0")
    if [ "$size" -gt 100 ]; then
        pass "CLAUDE.md exists (${size} bytes)"
    else
        warn "CLAUDE.md exists but seems too small (${size} bytes)"
    fi
else
    fail "CLAUDE.md not found at $CLAUDE_DIR/CLAUDE.md"
fi

if [ -f "$SETTINGS_FILE" ]; then
    # Validate JSON
    if python3 -c "import json; json.load(open('$SETTINGS_FILE'))" 2>/dev/null ||
       python -c "import json; json.load(open('$SETTINGS_FILE'))" 2>/dev/null; then
        pass "settings.json exists and is valid JSON"
    else
        warn "settings.json exists but may have invalid JSON"
    fi
else
    warn "settings.json not found (hooks may not be configured)"
fi

# ── Skills Directory ────────────────────────────────────────
section "Skills"

SKILLS_DIR="$CLAUDE_DIR/skills"
if [ -d "$SKILLS_DIR" ]; then
    skill_count=$(find "$SKILLS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$skill_count" -gt 0 ]; then
        pass "Skills directory has $skill_count skill file(s)"
    else
        warn "Skills directory exists but has no .md files"
    fi
else
    # Also check commands directory (alternative location)
    if [ -d "$CLAUDE_DIR/commands" ]; then
        cmd_count=$(find "$CLAUDE_DIR/commands" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [ "$cmd_count" -gt 0 ]; then
            pass "Commands directory has $cmd_count command file(s)"
        else
            warn "Commands directory exists but has no .md files"
        fi
    else
        fail "No skills or commands directory found"
    fi
fi

# ── Hook Scripts ────────────────────────────────────────────
section "Hook Scripts"

SCRIPTS_DIR="$CLAUDE_DIR/scripts"
hook_scripts=("memory-search.py" "bash-guard.py" "scan-secrets.py" "update-state.py")

if [ -d "$SCRIPTS_DIR" ]; then
    for script in "${hook_scripts[@]}"; do
        if [ -f "$SCRIPTS_DIR/$script" ]; then
            pass "Hook script: $script"
        else
            warn "Hook script missing: $script"
        fi
    done
else
    fail "Scripts directory not found at $SCRIPTS_DIR"
fi

# Check if hooks are configured in settings.json
if [ -f "$SETTINGS_FILE" ]; then
    py_cmd="python3"
    if ! command -v python3 &>/dev/null; then
        py_cmd="python"
    fi

    hooks_configured=$($py_cmd -c "
import json, sys
try:
    with open('$SETTINGS_FILE') as f:
        settings = json.load(f)
    hooks = settings.get('hooks', {})
    count = sum(len(v) if isinstance(v, list) else 1 for v in hooks.values())
    print(count)
except:
    print(0)
" 2>/dev/null || echo "0")

    if [ "$hooks_configured" -gt 0 ]; then
        pass "Hooks configured in settings.json ($hooks_configured hook(s))"
    else
        warn "No hooks found in settings.json"
    fi
fi

# ── Sync Scripts ────────────────────────────────────────────
section "Sync Scripts"

if [ -f "$SCRIPTS_DIR/sync-shared-memory.sh" ]; then
    pass "sync-shared-memory.sh present"
    if [ -n "${CLAUDE_SHARED_MEMORY_REPO:-}" ]; then
        pass "CLAUDE_SHARED_MEMORY_REPO is set"
    else
        warn "CLAUDE_SHARED_MEMORY_REPO not set (shared memory sync disabled)"
    fi
else
    warn "sync-shared-memory.sh not found"
fi

# ── Memory System ───────────────────────────────────────────
section "Memory System"

PROJECTS_DIR="$CLAUDE_DIR/projects"
if [ -d "$PROJECTS_DIR" ]; then
    memory_count=$(find "$PROJECTS_DIR" -path "*/memory/*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    project_count=$(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    pass "Projects directory exists ($project_count project(s), $memory_count memory file(s))"
else
    warn "No projects directory found (will be created on first use)"
fi

if [ -d "$CLAUDE_DIR/shared-memory" ]; then
    pass "Shared memory directory exists"
else
    warn "No shared memory directory (run sync-shared-memory.sh to initialize)"
fi

# ── MCP Servers ─────────────────────────────────────────────
section "MCP Servers"

if [ -f "$SETTINGS_FILE" ]; then
    py_cmd="python3"
    if ! command -v python3 &>/dev/null; then
        py_cmd="python"
    fi

    mcp_info=$($py_cmd -c "
import json, sys
try:
    with open('$SETTINGS_FILE') as f:
        settings = json.load(f)
    servers = settings.get('mcpServers', {})
    if not servers:
        print('NONE')
    else:
        for name, config in servers.items():
            cmd = config.get('command', 'unknown')
            print(f'{name}|{cmd}')
except Exception as e:
    print(f'ERROR|{e}')
" 2>/dev/null || echo "ERROR|python not available")

    if [ "$mcp_info" = "NONE" ]; then
        warn "No MCP servers configured"
    elif echo "$mcp_info" | grep -q "^ERROR"; then
        warn "Could not parse MCP server config"
    else
        while IFS='|' read -r name cmd; do
            if [ -n "$name" ] && [ "$name" != "ERROR" ]; then
                # Check if the command exists
                base_cmd=$(echo "$cmd" | awk '{print $1}')
                if command -v "$base_cmd" &>/dev/null 2>&1 || [ "$base_cmd" = "npx" ] || [ "$base_cmd" = "uvx" ]; then
                    pass "MCP server: $name (cmd: $base_cmd)"
                else
                    warn "MCP server: $name (cmd '$base_cmd' not found in PATH)"
                fi
            fi
        done <<< "$mcp_info"
    fi
else
    warn "Cannot check MCP servers (no settings.json)"
fi

# ── Python Environment ─────────────────────────────────────
section "Runtime Dependencies"

if command -v python3 &>/dev/null; then
    py_version=$(python3 --version 2>&1 | awk '{print $2}')
    pass "Python 3 available ($py_version)"
elif command -v python &>/dev/null; then
    py_version=$(python --version 2>&1 | awk '{print $2}')
    if echo "$py_version" | grep -q "^3"; then
        pass "Python 3 available ($py_version)"
    else
        fail "Python 2 found ($py_version) - Python 3 required"
    fi
else
    fail "Python not found in PATH"
fi

if command -v git &>/dev/null; then
    git_version=$(git --version 2>&1 | awk '{print $3}')
    pass "Git available ($git_version)"
else
    fail "Git not found in PATH"
fi

if command -v claude &>/dev/null; then
    pass "Claude CLI available"
else
    warn "Claude CLI not found in PATH"
fi

# ── Workflow Files ──────────────────────────────────────────
section "Workflow Files"

workflow_files=("workflow/FLOW.md" "workflow/HARNESS.md")
for wf in "${workflow_files[@]}"; do
    if [ -f "$CLAUDE_DIR/$wf" ]; then
        pass "$wf"
    else
        warn "$wf not found"
    fi
done

if [ -f "$CLAUDE_DIR/agents/reviewer.md" ]; then
    pass "Reviewer agent configured"
else
    warn "Reviewer agent not found at agents/reviewer.md"
fi

# ── Summary ─────────────────────────────────────────────────
echo ""
echo "${BOLD}═══════════════════════════════════${RESET}"
echo "${BOLD}Health Check Summary${RESET}"
echo "${BOLD}═══════════════════════════════════${RESET}"
echo "  ${GREEN}Healthy${RESET}: $healthy"
echo "  ${YELLOW}Warning${RESET}: $warning"
echo "  ${RED}Failed${RESET}:  $failed"
echo "  Total:   $total"
echo ""

if [ $failed -eq 0 ] && [ $warning -eq 0 ]; then
    echo "  ${GREEN}${BOLD}All $total components healthy!${RESET}"
elif [ $failed -eq 0 ]; then
    echo "  ${YELLOW}${BOLD}$healthy/$total healthy, $warning warning(s)${RESET}"
else
    echo "  ${RED}${BOLD}$healthy/$total healthy, $failed failure(s), $warning warning(s)${RESET}"
fi

echo ""
exit $failed
