#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# claude-setup  —  one-click Claude Code harness installer
#
# Installs a curated, layered Claude Code environment with role-based skill
# selection, persistent memory, security hooks, and observability.
#
# Layers:
#   0  ECC (Everything Claude Code)  — 181 skills, 47 agents, hooks, DevFleet
#   1  Methodology                   — superpowers, mattpocock/skills, impeccable
#   2  Research                      — last30days-skill, custom deep-research skill
#   3  Agents                        — agency-agents (100+ cross-domain agents)
#   4  Observability                 — HUD status line via settings.json
#   5  Memory & Security             — hooks, MCP memory, scripts
#   6  Config & Templates            — CLAUDE.md, role overlays, team templates
#   7  Skills                        — karpathy-guidelines, deep-research
#
# Supports: macOS, Linux, Windows (Git Bash / MSYS2)
# ──────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=""
MANIFEST_LAYERS=()
SELECTED_ROLES=()
OS=""
CLAUDE_HOME=""

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { printf "${CYAN}[INFO]${NC}  %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
error()   { printf "${RED}[ERR]${NC}   %s\n" "$1"; }
header()  { printf "\n${BOLD}── %s ──${NC}\n" "$1"; }

# ── Cleanup ───────────────────────────────────────────────────────────────────
cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}
trap cleanup EXIT

# ── OS Detection ──────────────────────────────────────────────────────────────
detect_os() {
  local uname_out
  uname_out="$(uname -s)"
  case "$uname_out" in
    MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
    Darwin*)               OS="macos"   ;;
    Linux*)                OS="linux"   ;;
    *)                     OS="linux"   ;;
  esac
}

set_claude_home() {
  if [[ "$OS" == "windows" && -n "${USERPROFILE:-}" ]]; then
    CLAUDE_HOME="$USERPROFILE/.claude"
  else
    CLAUDE_HOME="$HOME/.claude"
  fi
  info "CLAUDE_HOME = $CLAUDE_HOME"
}

# On Windows, npx is a .cmd batch file and cannot be spawned directly by
# processes that bypass the shell (e.g. Claude Code's MCP server launcher).
# This function returns the correct command + arg prefix for the platform.
#
# Usage:
#   local cmd args_prefix
#   mcp_npx_prefix cmd args_prefix
#   # Then build: "command": "$cmd", "args": [$args_prefix, "-y", "package"]
mcp_npx_prefix() {
  local -n _cmd=$1
  local -n _prefix=$2
  if [[ "$OS" == "windows" ]]; then
    _cmd="cmd"
    _prefix='"/c", "npx"'
  else
    _cmd="npx"
    _prefix=""
  fi
}

# ── Dependency installation ───────────────────────────────────────────────────
# Checks each required/optional tool and offers to install missing ones.
# Defaults: Y for required tools (Node, Python, jq), N for optional (LaTeX, Obsidian).
install_dependencies() {
  header "Installing dependencies"

  # ── Git (hard requirement — no package manager works without it) ──
  if ! command -v git &>/dev/null; then
    error "git is required but not found."
    case "$OS" in
      windows) error "Install Git from: https://git-scm.com/download/win" ;;
      macos)   error "Run: brew install git  OR install Xcode Command Line Tools" ;;
      linux)   error "Run: sudo apt install git  OR  sudo dnf install git" ;;
    esac
    exit 1
  else
    success "git: $(git --version)"
  fi

  # ── Node.js ──
  if ! command -v node &>/dev/null; then
    warn "Node.js not found"
    read -rp "  Install Node.js LTS now? [Y/n] " yn
    if [[ "${yn:-Y}" =~ ^[Yy]$ ]]; then
      case "$OS" in
        windows)
          info "Installing Node.js LTS via winget..."
          winget install OpenJS.NodeJS.LTS \
            --accept-package-agreements --accept-source-agreements 2>/dev/null \
            || warn "winget failed — install from https://nodejs.org"
          ;;
        macos)
          if command -v brew &>/dev/null; then
            brew install node@lts 2>/dev/null || brew install node
          else
            warn "Homebrew not found — install from https://nodejs.org"
          fi
          ;;
        linux)
          if command -v curl &>/dev/null; then
            info "Installing Node.js LTS via NodeSource..."
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - \
              && sudo apt-get install -y nodejs 2>/dev/null \
            || { command -v dnf &>/dev/null && sudo dnf install -y nodejs; } 2>/dev/null \
            || warn "Auto-install failed — install from https://nodejs.org"
          else
            warn "curl not found — install Node.js from https://nodejs.org"
          fi
          ;;
      esac
    fi
    if ! command -v node &>/dev/null; then
      error "Node.js still not found. Install it and re-run."
      exit 1
    fi
  else
    success "node: $(node --version)"
  fi

  # npx ships with Node >= 5.2; install separately only if missing
  if ! command -v npx &>/dev/null; then
    info "Installing npx..."
    npm install -g npx 2>/dev/null || warn "Could not install npx"
  else
    success "npx: found"
  fi

  # ── Claude Code CLI ──
  if ! command -v claude &>/dev/null; then
    warn "Claude Code CLI not found"
    read -rp "  Install Claude Code CLI now? [Y/n] " yn
    if [[ "${yn:-Y}" =~ ^[Yy]$ ]]; then
      info "Installing @anthropic-ai/claude-code..."
      npm install -g @anthropic-ai/claude-code \
        && success "Claude Code CLI installed" \
        || warn "Install failed — run: npm install -g @anthropic-ai/claude-code"
    fi
  else
    success "claude: $(claude --version 2>/dev/null | head -1 || echo found)"
  fi

  # ── Python 3 (needed by memory + security hooks) ──
  if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
    warn "Python not found (required for memory hooks)"
    read -rp "  Install Python 3 now? [Y/n] " yn
    if [[ "${yn:-Y}" =~ ^[Yy]$ ]]; then
      case "$OS" in
        windows)
          winget install Python.Python.3 \
            --accept-package-agreements --accept-source-agreements 2>/dev/null \
            || warn "winget failed — install from https://python.org"
          ;;
        macos)
          command -v brew &>/dev/null && brew install python3 \
            || warn "Install from https://python.org"
          ;;
        linux)
          sudo apt-get install -y python3 2>/dev/null \
          || sudo dnf install -y python3 2>/dev/null \
          || warn "Install python3 with your package manager"
          ;;
      esac
    fi
  else
    success "python: found"
  fi

  # ── uv (recommended Python package manager) ──
  if ! command -v uv &>/dev/null; then
    warn "uv not found (recommended Python package manager)"
    read -rp "  Install uv now? [Y/n] " yn
    if [[ "${yn:-Y}" =~ ^[Yy]$ ]]; then
      case "$OS" in
        windows)
          winget install astral-sh.uv \
            --accept-package-agreements --accept-source-agreements 2>/dev/null \
          || { command -v pip3 &>/dev/null && pip3 install uv; } 2>/dev/null \
          || warn "Install uv: https://github.com/astral-sh/uv"
          ;;
        *)
          curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null \
          || { command -v pip3 &>/dev/null && pip3 install uv; } 2>/dev/null \
          || warn "Install uv: curl -LsSf https://astral.sh/uv/install.sh | sh"
          # uv installs to ~/.local/bin — add to PATH for this session
          [[ -f "$HOME/.local/bin/uv" ]] && export PATH="$HOME/.local/bin:$PATH"
          ;;
      esac
      command -v uv &>/dev/null \
        && success "uv installed" \
        || warn "uv not in PATH — restart your shell after installation"
    fi
  else
    success "uv: $(uv --version)"
  fi

  # ── jq (required by HUD status line) ──
  if ! command -v jq &>/dev/null; then
    warn "jq not found (required by HUD status line)"
    read -rp "  Install jq now? [Y/n] " yn
    if [[ "${yn:-Y}" =~ ^[Yy]$ ]]; then
      case "$OS" in
        windows)
          winget install stedolan.jq \
            --accept-package-agreements --accept-source-agreements 2>/dev/null \
            || warn "Install jq: https://jqlang.github.io/jq/"
          ;;
        macos)
          command -v brew &>/dev/null && brew install jq \
            || warn "Install jq: brew install jq"
          ;;
        linux)
          sudo apt-get install -y jq 2>/dev/null \
          || sudo dnf install -y jq 2>/dev/null \
          || warn "Install jq with your package manager"
          ;;
      esac
      command -v jq &>/dev/null && success "jq installed"
    fi
  else
    success "jq: $(jq --version)"
  fi

  # ── LaTeX (optional — needed for PDF/docs skills) ──
  if ! command -v pdflatex &>/dev/null && ! command -v xelatex &>/dev/null; then
    warn "LaTeX not found (optional — needed for PDF generation skills)"
    read -rp "  Install LaTeX? (~1-2 GB download) [y/N] " yn
    if [[ "${yn:-N}" =~ ^[Yy]$ ]]; then
      case "$OS" in
        windows)
          info "Installing MiKTeX via winget..."
          winget install MiKTeX.MiKTeX \
            --accept-package-agreements --accept-source-agreements 2>/dev/null \
            || warn "Install MiKTeX from: https://miktex.org/download"
          ;;
        macos)
          command -v brew &>/dev/null \
            && brew install --cask mactex \
            || warn "Install MacTeX: https://tug.org/mactex/"
          ;;
        linux)
          info "Installing texlive-xetex..."
          sudo apt-get install -y texlive-xetex 2>/dev/null \
          || sudo dnf install -y texlive-xetex 2>/dev/null \
          || warn "Run: sudo apt install texlive-xetex"
          ;;
      esac
    else
      info "LaTeX skipped — /pdf and /docx skills will not work without it"
    fi
  else
    success "LaTeX: found"
  fi

  # ── Obsidian (optional — knowledge base integration) ──
  if ! command -v obsidian &>/dev/null; then
    warn "Obsidian not found (optional — knowledge base integration)"
    read -rp "  Install Obsidian? [y/N] " yn
    if [[ "${yn:-N}" =~ ^[Yy]$ ]]; then
      case "$OS" in
        windows)
          winget install Obsidian.Obsidian \
            --accept-package-agreements --accept-source-agreements 2>/dev/null \
            || warn "Install Obsidian: https://obsidian.md/download"
          ;;
        macos)
          command -v brew &>/dev/null \
            && brew install --cask obsidian \
            || warn "Install Obsidian: https://obsidian.md/download"
          ;;
        linux)
          info "Downloading Obsidian AppImage..."
          local obsidian_dest="$HOME/.local/bin/obsidian"
          mkdir -p "$HOME/.local/bin"
          curl -L \
            "https://github.com/obsidianmd/obsidian-releases/releases/latest/download/Obsidian.AppImage" \
            -o "$obsidian_dest" 2>/dev/null \
            && chmod +x "$obsidian_dest" \
            && success "Obsidian AppImage installed to $obsidian_dest" \
            || warn "Install Obsidian: https://obsidian.md/download"
          ;;
      esac
    else
      info "Obsidian skipped"
    fi
  else
    success "obsidian: found"
  fi
}

# ── Role Selection ────────────────────────────────────────────────────────────
select_roles() {
  header "Select your role(s)"
  echo ""
  echo "  Each role activates a curated subset of skills and agents."
  echo ""
  echo "  [1] Full-Stack Developer"
  echo "  [2] Backend Developer"
  echo "  [3] Frontend Developer / Designer"
  echo "  [4] Researcher / Analyst"
  echo "  [5] Product Manager"
  echo "  [6] Data Scientist / ML Engineer"
  echo "  [7] DevOps / SRE"
  echo "  [8] All roles (install everything)"
  echo ""
  read -rp "Enter selections (comma-separated, e.g. 1,3): " role_input

  if [[ -z "$role_input" ]]; then
    warn "No selection — defaulting to [8] All"
    role_input="8"
  fi

  IFS=',' read -ra choices <<< "$role_input"
  for choice in "${choices[@]}"; do
    choice="$(echo "$choice" | tr -d '[:space:]')"
    case "$choice" in
      1) SELECTED_ROLES+=("fullstack")   ;;
      2) SELECTED_ROLES+=("backend")     ;;
      3) SELECTED_ROLES+=("frontend")    ;;
      4) SELECTED_ROLES+=("researcher")  ;;
      5) SELECTED_ROLES+=("pm")          ;;
      6) SELECTED_ROLES+=("datascience") ;;
      7) SELECTED_ROLES+=("devops")      ;;
      8) SELECTED_ROLES=("fullstack" "backend" "frontend" "researcher" "pm" "datascience" "devops") ;;
      *) warn "Unknown selection: $choice — skipping" ;;
    esac
  done

  if [[ ${#SELECTED_ROLES[@]} -eq 0 ]]; then
    error "No valid roles selected."
    exit 1
  fi

  success "Roles: ${SELECTED_ROLES[*]}"
}

has_role() {
  local target="$1"
  for role in "${SELECTED_ROLES[@]}"; do
    [[ "$role" == "$target" ]] && return 0
  done
  return 1
}

has_any_role() {
  for target in "$@"; do
    has_role "$target" && return 0
  done
  return 1
}

# ── Layer 0: ECC ──────────────────────────────────────────────────────────────
# Everything Claude Code: 181 skills, 47 agents, hooks, DevFleet, continuous
# learning, context budget tools, skill routing table.
# Source: https://github.com/affaan-m/everything-claude-code (MIT)
install_layer0_ecc() {
  header "Layer 0: Everything Claude Code (base infrastructure)"

  if [[ -d "$CLAUDE_HOME/plugins/marketplaces/ecc" ]] \
     || [[ -f "$CLAUDE_HOME/skills/everything-claude-code.md" ]]; then
    warn "ECC already installed — skipping"
  else
    info "Running ECC installer (this may take a minute)..."
    if npx everything-claude-code install 2>/dev/null; then
      success "ECC installed"
    else
      warn "ECC installer returned non-zero — may be partial or already installed"
    fi
  fi
  MANIFEST_LAYERS+=("ecc")
}

# ── Layer 1: Methodology Skills ───────────────────────────────────────────────
# superpowers  — 14 skills: TDD, verification, Generator≠Evaluator principle
#   Source: https://github.com/obra/superpowers (MIT)
# mattpocock/skills — canonical SKILL.md format, TDD, PRD-to-plan, grill-me
#   Source: https://github.com/mattpocock/skills (MIT)
# impeccable — 21 UI/UX design skills (critique → polish pipeline)
#   Source: https://github.com/pbakaus/impeccable (Apache 2.0)
install_layer1_methodology() {
  header "Layer 1: Methodology skills"

  mkdir -p "$CLAUDE_HOME/skills"

  # superpowers
  local superpowers_dir="$TEMP_DIR/superpowers"
  info "Cloning superpowers (obra/superpowers)..."
  git clone --depth 1 \
    https://github.com/obra/superpowers.git \
    "$superpowers_dir" 2>/dev/null \
  || { warn "Could not clone superpowers — skipping"; }

  if [[ -d "$superpowers_dir/skills" ]]; then
    cp -r "$superpowers_dir/skills/"* "$CLAUDE_HOME/skills/" 2>/dev/null || true
    success "superpowers skills copied"
  fi

  # mattpocock/skills
  info "Installing mattpocock skills (TDD, PRD-to-plan, grill-me)..."
  npx skills add \
    mattpocock/skills/tdd \
    mattpocock/skills/prd-to-plan \
    mattpocock/skills/grill-me 2>/dev/null \
  || { warn "npx skills failed — mattpocock skills skipped"; }

  # impeccable — frontend/fullstack only
  if has_any_role "frontend" "fullstack"; then
    info "Installing impeccable design skills..."
    local impeccable_dir="$TEMP_DIR/impeccable"
    git clone --depth 1 \
      https://github.com/pbakaus/impeccable.git \
      "$impeccable_dir" 2>/dev/null \
    || { warn "Could not clone impeccable — skipping"; }

    if [[ -d "$impeccable_dir/skills" ]]; then
      cp -r "$impeccable_dir/skills/"* "$CLAUDE_HOME/skills/" 2>/dev/null || true
      success "impeccable skills installed"
    fi
  fi

  success "Layer 1 complete"
  MANIFEST_LAYERS+=("methodology")
}

# ── Layer 2: Research Skills ──────────────────────────────────────────────────
# last30days-skill — multi-platform trend research (Reddit, X, HN, YouTube, etc.)
#   Source: https://github.com/mvanhorn/last30days-skill (MIT)
#   Note: Requires ScrapeCreators API key (set SCRAPECREATORS_API_KEY)
install_layer2_research() {
  header "Layer 2: Research skills"

  if has_any_role "researcher" "datascience" "fullstack"; then
    info "Installing last30days-skill..."
    npx skills add mvanhorn/last30days-skill 2>/dev/null \
    || { warn "Could not install last30days-skill (may need ScrapeCreators API key)"; }
    info "Note: Set SCRAPECREATORS_API_KEY env var to activate last30days-skill"
    success "Research skills installed"
  else
    info "Skipping research skills (no researcher/datascience/fullstack role)"
  fi

  MANIFEST_LAYERS+=("research")
}

# ── Layer 3: Agents ───────────────────────────────────────────────────────────
# agency-agents — 100+ cross-domain agents (engineering, design, marketing,
#   sales, product, strategy, support, academic)
#   Source: https://github.com/msitarzewski/agency-agents (MIT)
install_layer3_agents() {
  header "Layer 3: Agents (agency-agents)"

  local agents_dir="$TEMP_DIR/agency-agents"
  info "Cloning agency-agents (msitarzewski/agency-agents)..."
  git clone --depth 1 \
    https://github.com/msitarzewski/agency-agents.git \
    "$agents_dir" 2>/dev/null \
  || {
    warn "Could not clone agency-agents — skipping"
    MANIFEST_LAYERS+=("agents")
    return 0
  }

  mkdir -p "$CLAUDE_HOME/agents"

  if [[ -f "$agents_dir/scripts/install.sh" ]]; then
    info "Running agency-agents install script..."
    local role_args=()
    for role in "${SELECTED_ROLES[@]}"; do
      role_args+=("--role" "$role")
    done
    bash "$agents_dir/scripts/install.sh" --tool claude-code "${role_args[@]}" \
      2>/dev/null \
    || {
      warn "agency-agents script returned non-zero — falling back to direct copy"
      [[ -d "$agents_dir/agents" ]] && \
        cp -r "$agents_dir/agents/"* "$CLAUDE_HOME/agents/" 2>/dev/null || true
    }
  elif [[ -d "$agents_dir/agents" ]]; then
    cp -r "$agents_dir/agents/"* "$CLAUDE_HOME/agents/" 2>/dev/null || true
    info "Agent files copied directly"
  else
    warn "No agents directory found in agency-agents"
  fi

  success "Layer 3 complete"
  MANIFEST_LAYERS+=("agents")
}

# ── Layer 4: Observability (HUD) ──────────────────────────────────────────────
# claude-hud — real-time status line showing: user:path branch* ctx:% model time
#   Source: https://github.com/jarrodwatts/claude-hud (MIT)
#
# The HUD is not a separate install — it is configured via the statusLine key
# in ~/.claude/settings.json. The command below reads context data from stdin
# (passed by Claude Code) and outputs a formatted, color-coded status string.
#
# Output example:  user:~/project main* ctx:73% claude-sonnet-4-6 14:30 todos:2
install_layer4_hud() {
  header "Layer 4: HUD status line"

  local settings_file="$CLAUDE_HOME/settings.json"

  # Ensure settings.json exists
  if [[ ! -f "$settings_file" ]]; then
    echo '{}' > "$settings_file"
  fi

  if grep -q '"statusLine"' "$settings_file" 2>/dev/null; then
    info "statusLine already configured — skipping"
  else
    info "Writing statusLine config to settings.json..."
    _merge_json "$settings_file" 'statusLine' '{
  "type": "command",
  "command": "input=$(cat); user=$(whoami); cwd=$(echo \"$input\" | jq -r '"'"'.workspace.current_dir'"'"' | sed \"s|$HOME|~|g\"); model=$(echo \"$input\" | jq -r '"'"'.model.display_name'"'"'); time=$(date +%H:%M); remaining=$(echo \"$input\" | jq -r '"'"'.context_window.remaining_percentage // empty'"'"'); transcript=$(echo \"$input\" | jq -r '"'"'.transcript_path'"'"'); todo_count=$([ -f \"$transcript\" ] && grep -c '"'"'\"type\":\"todo\"'"'"' \"$transcript\" 2>/dev/null || echo 0); cd \"$(echo \"$input\" | jq -r '"'"'.workspace.current_dir'"'"')\" 2>/dev/null; branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '"'"''"'"'); status='"'"''"'"'; [ -n \"$branch\" ] && { [ -n \"$(git status --porcelain 2>/dev/null)\" ] && status='"'"'*'"'"'; }; B='"'"'\\033[38;2;30;102;245m'"'"'; G='"'"'\\033[38;2;64;160;43m'"'"'; Y='"'"'\\033[38;2;223;142;29m'"'"'; M='"'"'\\033[38;2;136;57;239m'"'"'; C='"'"'\\033[38;2;23;146;153m'"'"'; R='"'"'\\033[0m'"'"'; T='"'"'\\033[38;2;76;79;105m'"'"'; printf \"${C}${user}${R}:${B}${cwd}${R}\"; [ -n \"$branch\" ] && printf \" ${G}${branch}${Y}${status}${R}\"; [ -n \"$remaining\" ] && printf \" ${M}ctx:${remaining}%%${R}\"; printf \" ${T}${model}${R} ${Y}${time}${R}\"; [ \"$todo_count\" -gt 0 ] && printf \" ${C}todos:${todo_count}${R}\"; echo"
}'
    success "HUD status line configured"
  fi

  success "Layer 4 complete"
  MANIFEST_LAYERS+=("hud")
}

# ── Layer 5: Memory & Security ────────────────────────────────────────────────
# Installs:
#   - memory-search.py   : UserPromptSubmit hook — TF-IDF memory injection
#   - bash-guard.py      : PreToolUse hook — blocks dangerous commands
#   - scan-secrets.py    : PreToolUse hook — detects hardcoded secrets
#   - update-state.py    : Stop hook — auto-updates session state
#   - MCP memory server  : Cross-session knowledge graph
#
# Windows MCP fix: npx is a .cmd batch file on Windows and cannot be spawned
# directly. All MCP servers use "command": "cmd", "args": ["/c", "npx", ...]
# on Windows to route through cmd.exe which can resolve .cmd files.
install_layer5_memory() {
  header "Layer 5: Memory system & security hooks"

  mkdir -p "$CLAUDE_HOME/scripts"

  # Copy hook scripts from this repo
  if [[ -d "$SCRIPT_DIR/scripts" ]]; then
    local count=0
    for f in "$SCRIPT_DIR/scripts/"*; do
      [[ -f "$f" ]] || continue
      cp "$f" "$CLAUDE_HOME/scripts/"
      count=$((count + 1))
    done
    [[ $count -gt 0 ]] && success "Copied $count script(s) to $CLAUDE_HOME/scripts/"
    chmod +x "$CLAUDE_HOME/scripts/"*.py 2>/dev/null || true
    chmod +x "$CLAUDE_HOME/scripts/"*.sh 2>/dev/null || true
  else
    warn "No scripts/ directory found — skipping script copy"
  fi

  local settings_file="$CLAUDE_HOME/settings.json"
  [[ -f "$settings_file" ]] || echo '{}' > "$settings_file"

  # Determine MCP command based on OS
  # Windows: wrap npx with cmd /c to work around .cmd file spawn limitation
  local mcp_cmd mcp_prefix
  if [[ "$OS" == "windows" ]]; then
    mcp_cmd='"cmd"'
    mcp_prefix='"\/c", "npx"'
  else
    mcp_cmd='"npx"'
    mcp_prefix='"npx"'
  fi

  # Add MCP memory server if not present
  if grep -q '"memory"' "$settings_file" 2>/dev/null; then
    info "MCP memory server already in settings.json"
  else
    info "Adding MCP memory server to settings.json..."
    _add_mcp_server "$settings_file" "memory" "$mcp_cmd" "$mcp_prefix" \
      '"-y", "@modelcontextprotocol/server-memory"' \
      "\"MEMORY_FILE_PATH\": \"$CLAUDE_HOME/memory/entities.jsonl\""
    mkdir -p "$CLAUDE_HOME/memory"
    success "MCP memory server configured"
  fi

  # Add security + memory hooks to settings.json
  if grep -q '"hooks"' "$settings_file" 2>/dev/null; then
    info "Hooks already configured in settings.json"
  else
    info "Writing hooks to settings.json..."
    _merge_json_raw "$settings_file" '"hooks"' '{
    "SessionStart": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "cat ~/.claude/projects/$(basename $PWD 2>/dev/null)/state.md 2>/dev/null || true",
        "timeout": 5000
      }]
    }],
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude/scripts/memory-search.py 2>/dev/null || true",
        "timeout": 3000
      }]
    }],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "python3 ~/.claude/scripts/bash-guard.py",
          "timeout": 2000
        }]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [{
          "type": "command",
          "command": "python3 ~/.claude/scripts/scan-secrets.py",
          "timeout": 2000
        }]
      }
    ],
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude/scripts/update-state.py",
        "timeout": 3000
      }]
    }]
  }'
    success "Hooks configured"
  fi

  success "Layer 5 complete"
  MANIFEST_LAYERS+=("memory")
}

# ── Layer 6: Config & Templates ───────────────────────────────────────────────
# Installs CLAUDE.md navigation index, role overlays, and team templates.
install_layer6_custom() {
  header "Layer 6: Config files & templates"

  # CLAUDE.md global index
  if [[ -f "$SCRIPT_DIR/config/CLAUDE.md" ]]; then
    if [[ -f "$CLAUDE_HOME/CLAUDE.md" ]]; then
      warn "CLAUDE.md already exists — backing up to CLAUDE.md.bak"
      cp "$CLAUDE_HOME/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md.bak"
    fi
    cp "$SCRIPT_DIR/config/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
    success "CLAUDE.md installed"
  fi

  # Role overlays
  if [[ -d "$SCRIPT_DIR/config/roles" ]]; then
    mkdir -p "$CLAUDE_HOME/config/roles"
    local count=0
    for f in "$SCRIPT_DIR/config/roles/"*; do
      [[ -f "$f" ]] || continue
      cp "$f" "$CLAUDE_HOME/config/roles/"
      count=$((count + 1))
    done
    [[ $count -gt 0 ]] && success "Copied $count role overlay(s)"
  fi

  # Team templates
  if [[ -d "$SCRIPT_DIR/teams/templates" ]]; then
    mkdir -p "$CLAUDE_HOME/teams/templates"
    local count=0
    for f in "$SCRIPT_DIR/teams/templates/"*; do
      [[ -f "$f" ]] || continue
      cp "$f" "$CLAUDE_HOME/teams/templates/"
      count=$((count + 1))
    done
    [[ $count -gt 0 ]] && success "Copied $count team template(s)"
  fi

  success "Layer 6 complete"
  MANIFEST_LAYERS+=("custom")
}

# ── Layer 7: Skills ───────────────────────────────────────────────────────────
# Installs independently-written skills that implement patterns from:
#
#   karpathy-guidelines — 4 coding principles (Think Before Coding, Simplicity
#     First, Surgical Changes, Goal-Driven Execution). Patterns inspired by
#     forrestchang/andrej-karpathy-skills (MIT). Independently implemented.
#
#   deep-research — 5-stage research pipeline with anti-sycophancy guards,
#     IRON RULE context anchors, material passport provenance tracking, and
#     4 depth modes. Patterns inspired by Imbad0202/academic-research-skills
#     (CC BY-NC). Independently implemented — no source copied.
install_layer7_skills() {
  header "Layer 7: Skills"

  mkdir -p "$CLAUDE_HOME/skills"

  if [[ -d "$SCRIPT_DIR/skills" ]]; then
    local count=0
    for skill_dir in "$SCRIPT_DIR/skills/"*/; do
      [[ -d "$skill_dir" ]] || continue
      local skill_name
      skill_name="$(basename "$skill_dir")"
      mkdir -p "$CLAUDE_HOME/skills/$skill_name"
      cp -r "$skill_dir"* "$CLAUDE_HOME/skills/$skill_name/" 2>/dev/null || true
      info "Installed skill: $skill_name"
      count=$((count + 1))
    done
    [[ $count -gt 0 ]] && success "Installed $count skill(s)"
  else
    warn "No skills/ directory in repo — skipping"
  fi

  success "Layer 7 complete"
  MANIFEST_LAYERS+=("skills")
}

# ── JSON helpers ──────────────────────────────────────────────────────────────
# These helpers use python3 (preferred) or python to merge keys into settings.json
# without clobbering existing values.

_python_cmd() {
  if command -v python3 &>/dev/null; then echo "python3"
  elif command -v python &>/dev/null; then echo "python"
  else echo ""; fi
}

_merge_json() {
  local file="$1" key="$2" value="$3"
  local py; py="$(_python_cmd)"
  [[ -z "$py" ]] && { warn "No python — cannot merge $key into settings.json"; return; }
  "$py" - "$file" "$key" "$value" <<'PYEOF'
import json, sys
file, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(file) as f: cfg = json.load(f)
cfg[key] = json.loads(value)
with open(file, "w") as f: json.dump(cfg, f, indent=2)
PYEOF
}

_merge_json_raw() {
  local file="$1" key="$2" value="$3"
  local py; py="$(_python_cmd)"
  [[ -z "$py" ]] && { warn "No python — cannot merge $key into settings.json"; return; }
  "$py" - <<PYEOF
import json
file = """$file"""
with open(file) as f: cfg = json.load(f)
cfg[$key] = $value
with open(file, "w") as f: json.dump(cfg, f, indent=2)
PYEOF
}

_add_mcp_server() {
  local file="$1" name="$2" cmd="$3" prefix="$4" extra_args="$5" env_kv="${6:-}"
  local py; py="$(_python_cmd)"
  [[ -z "$py" ]] && { warn "No python — cannot add MCP server $name"; return; }
  "$py" - <<PYEOF
import json
file = """$file"""
name = """$name"""
cmd = $cmd
extra_args = [$extra_args]
env_kv = """$env_kv"""

with open(file) as f: cfg = json.load(f)
cfg.setdefault("mcpServers", {})

# Build args: on Windows cmd is "cmd" and we prepend /c npx
import platform, os
is_windows = (os.name == "nt" or "windows" in os.environ.get("OS","").lower())
if is_windows:
    args = ["/c", "npx"] + extra_args
    cfg["mcpServers"][name] = {"type": "stdio", "command": "cmd", "args": args}
else:
    args = extra_args
    cfg["mcpServers"][name] = {"type": "stdio", "command": "npx", "args": args}

if env_kv.strip():
    k, _, v = env_kv.partition('": "')
    k = k.strip().strip('"')
    v = v.strip().strip('"')
    cfg["mcpServers"][name]["env"] = {k: v}

with open(file, "w") as f: json.dump(cfg, f, indent=2)
PYEOF
}

# ── Attribution ───────────────────────────────────────────────────────────────
generate_attribution() {
  header "Writing attribution"

  cp "$SCRIPT_DIR/ATTRIBUTION.md" "$CLAUDE_HOME/ATTRIBUTION.md" 2>/dev/null \
  || {
    # Fallback: write minimal attribution inline
    cat > "$CLAUDE_HOME/ATTRIBUTION.md" <<'ATTR_EOF'
# Claude Code Setup — Attribution

See https://github.com/hihihhi/claude-setup/blob/main/ATTRIBUTION.md
for the full list of bundled components and pattern-derived skills.
ATTR_EOF
  }
  success "ATTRIBUTION.md written"

  # Collect license files from cloned repos
  mkdir -p "$CLAUDE_HOME/licenses"
  if [[ -d "$SCRIPT_DIR/licenses" ]]; then
    local count=0
    for f in "$SCRIPT_DIR/licenses/"*; do
      [[ -f "$f" ]] || continue
      cp "$f" "$CLAUDE_HOME/licenses/"
      count=$((count + 1))
    done
    [[ $count -gt 0 ]] && success "Copied $count license file(s)"
  fi

  for repo_dir in "$TEMP_DIR"/*/; do
    [[ -d "$repo_dir" ]] || continue
    local name; name="$(basename "$repo_dir")"
    for lic in LICENSE LICENSE.md LICENSE.txt; do
      [[ -f "${repo_dir}${lic}" ]] && \
        cp "${repo_dir}${lic}" "$CLAUDE_HOME/licenses/${name}-${lic}" && break
    done
  done
}

# ── Manifest ──────────────────────────────────────────────────────────────────
write_manifest() {
  header "Writing install manifest"

  local roles_json
  roles_json="$(printf '%s\n' "${SELECTED_ROLES[@]}" | \
    awk 'BEGIN{printf "["} NR>1{printf ","} {printf "\"%s\"",$0} END{printf "]"}')"

  local layers_json
  layers_json="$(printf '%s\n' "${MANIFEST_LAYERS[@]}" | \
    awk 'BEGIN{printf "["} NR>1{printf ","} {printf "\"%s\"",$0} END{printf "]"}')"

  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")"

  cat > "$CLAUDE_HOME/claude-setup-manifest.json" <<MANIFEST_EOF
{
  "installer": "claude-setup",
  "version": "1.2.0",
  "installedAt": "$ts",
  "os": "$OS",
  "claudeHome": "$CLAUDE_HOME",
  "roles": $roles_json,
  "layers": $layers_json,
  "repo": "https://github.com/hihihhi/claude-setup"
}
MANIFEST_EOF
  success "Manifest written to $CLAUDE_HOME/claude-setup-manifest.json"
}

# ── Smoke Test ────────────────────────────────────────────────────────────────
run_smoke_test() {
  header "Smoke test"

  local passed=0 failed=0

  check_item() {
    local label="$1" path="$2"
    if [[ -e "$path" ]]; then
      success "$label"
      passed=$((passed + 1))
    else
      warn "MISSING: $label → $path"
      failed=$((failed + 1))
    fi
  }

  check_item "CLAUDE_HOME"                     "$CLAUDE_HOME"
  check_item "skills/"                         "$CLAUDE_HOME/skills"
  check_item "scripts/"                        "$CLAUDE_HOME/scripts"
  check_item "agents/"                         "$CLAUDE_HOME/agents"
  check_item "memory-search.py"                "$CLAUDE_HOME/scripts/memory-search.py"
  check_item "bash-guard.py"                   "$CLAUDE_HOME/scripts/bash-guard.py"
  check_item "scan-secrets.py"                 "$CLAUDE_HOME/scripts/scan-secrets.py"
  check_item "karpathy-guidelines skill"       "$CLAUDE_HOME/skills/karpathy-guidelines"
  check_item "deep-research skill"             "$CLAUDE_HOME/skills/deep-research"
  check_item "settings.json"                   "$CLAUDE_HOME/settings.json"
  check_item "ATTRIBUTION.md"                  "$CLAUDE_HOME/ATTRIBUTION.md"
  check_item "claude-setup-manifest.json"      "$CLAUDE_HOME/claude-setup-manifest.json"
  [[ -f "$CLAUDE_HOME/CLAUDE.md" ]] && \
    check_item "CLAUDE.md"                     "$CLAUDE_HOME/CLAUDE.md"

  echo ""
  if [[ "$failed" -eq 0 ]]; then
    success "All $passed checks passed"
  else
    warn "$passed passed, $failed warnings — run health-check.sh for details"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  printf "${BOLD}${CYAN}"
  echo "╔════════════════════════════════════════════════╗"
  echo "║     Claude Code Setup Installer  v1.2.0       ║"
  echo "║     https://github.com/hihihhi/claude-setup   ║"
  echo "╚════════════════════════════════════════════════╝"
  printf "${NC}\n"

  detect_os
  info "OS: $OS"

  set_claude_home
  mkdir -p "$CLAUDE_HOME"

  TEMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t claude-setup)"
  info "Temp dir: $TEMP_DIR"

  install_dependencies
  select_roles

  install_layer0_ecc
  install_layer1_methodology
  install_layer2_research
  install_layer3_agents
  install_layer4_hud
  install_layer5_memory
  install_layer6_custom
  install_layer7_skills
  generate_attribution
  write_manifest
  run_smoke_test

  echo ""
  printf "${BOLD}${GREEN}"
  echo "╔════════════════════════════════════════════════╗"
  echo "║         Installation complete!                 ║"
  echo "╚════════════════════════════════════════════════╝"
  printf "${NC}\n"
  info "Restart Claude Code for all changes to take effect."
  info "CLAUDE_HOME : $CLAUDE_HOME"
  info "Roles       : ${SELECTED_ROLES[*]}"
  info "Layers      : ${MANIFEST_LAYERS[*]}"
  echo ""
}

main "$@"
