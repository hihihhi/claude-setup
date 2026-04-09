#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────
# igsl-claude-setup installer
# Installs a curated Claude Code environment with role-based layers.
# ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=""
MANIFEST_LAYERS=()
SELECTED_ROLES=()

# ── Colors ────────────────────────────────────────────────────────────
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

# ── Cleanup ───────────────────────────────────────────────────────────
cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}
trap cleanup EXIT

# ── OS Detection ──────────────────────────────────────────────────────
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
  if [[ "$OS" == "windows" ]]; then
    if [[ -n "${USERPROFILE:-}" ]]; then
      CLAUDE_HOME="$USERPROFILE/.claude"
    else
      CLAUDE_HOME="$HOME/.claude"
    fi
  else
    CLAUDE_HOME="$HOME/.claude"
  fi
  info "CLAUDE_HOME = $CLAUDE_HOME"
}

# ── Prerequisite checks ──────────────────────────────────────────────
check_prerequisites() {
  header "Checking prerequisites"
  local missing=0

  if ! command -v git &>/dev/null; then
    error "git is not installed"
    missing=1
  else
    success "git found: $(git --version)"
  fi

  if ! command -v node &>/dev/null; then
    error "node is not installed"
    missing=1
  else
    success "node found: $(node --version)"
  fi

  if ! command -v npx &>/dev/null; then
    error "npx is not installed"
    missing=1
  else
    success "npx found"
  fi

  if [[ "$missing" -eq 1 ]]; then
    error "Missing prerequisites. Install them and re-run."
    exit 1
  fi
}

# ── Role Selection ────────────────────────────────────────────────────
select_roles() {
  header "Select roles to install"
  echo ""
  echo "  [1] Full-Stack Developer"
  echo "  [2] Backend Developer"
  echo "  [3] Frontend Developer / Designer"
  echo "  [4] Researcher / Analyst"
  echo "  [5] Product Manager"
  echo "  [6] Data Scientist / ML Engineer"
  echo "  [7] DevOps / SRE"
  echo "  [8] All (install everything)"
  echo ""
  read -rp "Enter selections (comma-separated, e.g. 1,3,6): " role_input

  if [[ -z "$role_input" ]]; then
    warn "No selection made — defaulting to [8] All"
    role_input="8"
  fi

  IFS=',' read -ra choices <<< "$role_input"
  for choice in "${choices[@]}"; do
    choice="$(echo "$choice" | tr -d '[:space:]')"
    case "$choice" in
      1) SELECTED_ROLES+=("fullstack")  ;;
      2) SELECTED_ROLES+=("backend")    ;;
      3) SELECTED_ROLES+=("frontend")   ;;
      4) SELECTED_ROLES+=("researcher") ;;
      5) SELECTED_ROLES+=("pm")         ;;
      6) SELECTED_ROLES+=("datascience");;
      7) SELECTED_ROLES+=("devops")     ;;
      8) SELECTED_ROLES=("fullstack" "backend" "frontend" "researcher" "pm" "datascience" "devops") ;;
      *) warn "Unknown selection: $choice — skipping" ;;
    esac
  done

  if [[ ${#SELECTED_ROLES[@]} -eq 0 ]]; then
    error "No valid roles selected. Exiting."
    exit 1
  fi

  success "Selected roles: ${SELECTED_ROLES[*]}"
}

has_role() {
  local target="$1"
  for role in "${SELECTED_ROLES[@]}"; do
    if [[ "$role" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

has_any_role() {
  for target in "$@"; do
    if has_role "$target"; then
      return 0
    fi
  done
  return 1
}

# ── Layer 0: ECC (Everything Claude Code) ─────────────────────────────
install_layer0_ecc() {
  header "Layer 0: Everything Claude Code"

  if [[ -f "$CLAUDE_HOME/skills/everything-claude-code.md" ]] \
     || [[ -d "$CLAUDE_HOME/skills/everything-claude-code" ]]; then
    warn "ECC already installed — skipping"
  else
    info "Installing everything-claude-code..."
    npx everything-claude-code install
    success "ECC installed"
  fi
  MANIFEST_LAYERS+=("ecc")
}

# ── Layer 1: Methodology Skills ───────────────────────────────────────
install_layer1_methodology() {
  header "Layer 1: Methodology Skills"

  mkdir -p "$CLAUDE_HOME/skills"

  # Clone superpowers to temp and copy skills
  local superpowers_dir="$TEMP_DIR/superpowers"
  if [[ -d "$superpowers_dir" ]]; then
    info "Superpowers already cloned"
  else
    info "Cloning claude-code-superpowers..."
    git clone --depth 1 \
      https://github.com/anthropics/claude-code-superpowers.git \
      "$superpowers_dir" 2>/dev/null || {
        warn "Could not clone superpowers — skipping"
      }
  fi

  if [[ -d "$superpowers_dir/skills" ]]; then
    cp -r "$superpowers_dir/skills/"* "$CLAUDE_HOME/skills/" 2>/dev/null || true
    success "Superpowers skills copied"
  fi

  # Core methodology skills
  info "Installing TDD and PRD-to-plan skills..."
  npx skills add mattpocock/skills/tdd mattpocock/skills/prd-to-plan 2>/dev/null || {
    warn "Could not install mattpocock skills (npx skills may not be available)"
  }

  # Frontend-specific: impeccable skills
  if has_any_role "frontend" "fullstack"; then
    info "Installing impeccable skills for frontend role..."
    npx skills add anthropics/impeccable/audit \
      anthropics/impeccable/critique \
      anthropics/impeccable/polish \
      anthropics/impeccable/typeset 2>/dev/null || {
        warn "Could not install impeccable skills"
      }
    success "Impeccable skills installed"
  fi

  success "Layer 1 complete"
  MANIFEST_LAYERS+=("methodology")
}

# ── Layer 2: Research Skills ──────────────────────────────────────────
install_layer2_research() {
  header "Layer 2: Research Skills"

  if has_any_role "researcher" "datascience"; then
    info "Installing research skills..."
    npx skills add mvanhorn/last30days-skill 2>/dev/null || {
      warn "Could not install last30days-skill"
    }
    success "Research skills installed"
  else
    info "No researcher/data-science role selected — skipping"
  fi
  MANIFEST_LAYERS+=("research")
}

# ── Layer 3: Agents ───────────────────────────────────────────────────
install_layer3_agents() {
  header "Layer 3: Agents"

  local agents_dir="$TEMP_DIR/agency-agents"
  info "Cloning agency-agents..."
  git clone --depth 1 \
    https://github.com/anthropics/agency-agents.git \
    "$agents_dir" 2>/dev/null || {
      warn "Could not clone agency-agents — skipping"
      MANIFEST_LAYERS+=("agents")
      return 0
    }

  if [[ -f "$agents_dir/install.sh" ]]; then
    info "Running agency-agents installer (roles: ${SELECTED_ROLES[*]})..."
    local role_args=""
    for role in "${SELECTED_ROLES[@]}"; do
      role_args+=" --role $role"
    done
    # shellcheck disable=SC2086
    bash "$agents_dir/install.sh" $role_args 2>/dev/null || {
      warn "agency-agents install script returned non-zero (may be partial)"
    }
    success "Agents installed"
  else
    # Fallback: copy agent markdown files directly
    mkdir -p "$CLAUDE_HOME/agents"
    if [[ -d "$agents_dir/agents" ]]; then
      cp -r "$agents_dir/agents/"* "$CLAUDE_HOME/agents/" 2>/dev/null || true
      success "Agent files copied to $CLAUDE_HOME/agents/"
    else
      warn "No agents directory found in agency-agents repo"
    fi
  fi
  MANIFEST_LAYERS+=("agents")
}

# ── Layer 4: HUD ──────────────────────────────────────────────────────
install_layer4_hud() {
  header "Layer 4: Claude HUD"

  info "Installing claude-hud..."
  npx claude-hud install 2>/dev/null || {
    warn "Could not install claude-hud (may not be published yet)"
  }
  success "Layer 4 complete"
  MANIFEST_LAYERS+=("hud")
}

# ── Layer 5: Memory System ────────────────────────────────────────────
install_layer5_memory() {
  header "Layer 5: Memory System"

  mkdir -p "$CLAUDE_HOME/scripts"

  # Copy memory scripts from this repo
  if [[ -d "$SCRIPT_DIR/scripts" ]]; then
    local count=0
    for f in "$SCRIPT_DIR/scripts/"*; do
      if [[ -f "$f" ]]; then
        cp "$f" "$CLAUDE_HOME/scripts/"
        count=$((count + 1))
      fi
    done
    if [[ $count -gt 0 ]]; then
      success "Copied $count script(s) to $CLAUDE_HOME/scripts/"
    else
      info "No scripts found in $SCRIPT_DIR/scripts/ (directory is empty)"
    fi
  else
    warn "No scripts/ directory in repo — skipping script copy"
  fi

  # Configure MCP memory server in settings.json
  local settings_file="$CLAUDE_HOME/settings.json"
  if [[ -f "$settings_file" ]]; then
    # Check if memory server already configured
    if grep -q '"memory"' "$settings_file" 2>/dev/null; then
      info "Memory MCP server already configured in settings.json"
    else
      info "Adding memory MCP server to settings.json..."
      # Use a temp file to avoid clobbering
      local tmp_settings="$TEMP_DIR/settings_merged.json"
      if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('$settings_file', 'r') as f:
    cfg = json.load(f)
cfg.setdefault('mcpServers', {})
cfg['mcpServers']['memory'] = {
    'command': 'npx',
    'args': ['-y', '@anthropic/mcp-memory']
}
with open('$tmp_settings', 'w') as f:
    json.dump(cfg, f, indent=2)
" && mv "$tmp_settings" "$settings_file"
        success "Memory MCP server added to settings.json"
      elif command -v python &>/dev/null; then
        python -c "
import json, sys
with open('$settings_file', 'r') as f:
    cfg = json.load(f)
cfg.setdefault('mcpServers', {})
cfg['mcpServers']['memory'] = {
    'command': 'npx',
    'args': ['-y', '@anthropic/mcp-memory']
}
with open('$tmp_settings', 'w') as f:
    json.dump(cfg, f, indent=2)
" && mv "$tmp_settings" "$settings_file"
        success "Memory MCP server added to settings.json"
      else
        warn "No python found — cannot merge settings.json. Add memory MCP manually."
      fi
    fi
  else
    info "Creating settings.json with memory MCP server..."
    cat > "$settings_file" <<'SETTINGS_EOF'
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-memory"]
    }
  }
}
SETTINGS_EOF
    success "settings.json created"
  fi

  MANIFEST_LAYERS+=("memory")
}

# ── Layer 6: Custom Templates ─────────────────────────────────────────
install_layer6_custom() {
  header "Layer 6: Custom Templates"

  # Copy CLAUDE.md template
  if [[ -f "$SCRIPT_DIR/config/CLAUDE.md" ]]; then
    if [[ -f "$CLAUDE_HOME/CLAUDE.md" ]]; then
      warn "CLAUDE.md already exists — backing up to CLAUDE.md.bak"
      cp "$CLAUDE_HOME/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md.bak"
    fi
    cp "$SCRIPT_DIR/config/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
    success "CLAUDE.md template installed"
  else
    info "No CLAUDE.md template found in config/ — skipping"
  fi

  # Copy role overlays
  if [[ -d "$SCRIPT_DIR/config/roles" ]]; then
    mkdir -p "$CLAUDE_HOME/config/roles"
    local count=0
    for f in "$SCRIPT_DIR/config/roles/"*; do
      if [[ -f "$f" ]]; then
        cp "$f" "$CLAUDE_HOME/config/roles/"
        count=$((count + 1))
      fi
    done
    if [[ $count -gt 0 ]]; then
      success "Copied $count role overlay(s)"
    else
      info "No role overlays in config/roles/ (directory is empty)"
    fi
  fi

  # Copy team templates
  if [[ -d "$SCRIPT_DIR/teams/templates" ]]; then
    mkdir -p "$CLAUDE_HOME/teams/templates"
    local count=0
    for f in "$SCRIPT_DIR/teams/templates/"*; do
      if [[ -f "$f" ]]; then
        cp "$f" "$CLAUDE_HOME/teams/templates/"
        count=$((count + 1))
      fi
    done
    if [[ $count -gt 0 ]]; then
      success "Copied $count team template(s)"
    else
      info "No team templates found (directory is empty)"
    fi
  fi

  MANIFEST_LAYERS+=("custom")
}

# ── Attribution & Licenses ────────────────────────────────────────────
generate_attribution() {
  header "Generating attribution"

  cat > "$CLAUDE_HOME/ATTRIBUTION.md" <<'ATTR_EOF'
# IGSL Claude Setup — Attribution

This environment bundles the following open-source components:

| Component | Source | License |
|-----------|--------|---------|
| Everything Claude Code (ECC) | https://github.com/anthropics/everything-claude-code | MIT |
| Claude Code Superpowers | https://github.com/anthropics/claude-code-superpowers | MIT |
| mattpocock/skills (TDD, PRD-to-plan) | https://github.com/mattpocock/skills | MIT |
| Impeccable Skills | https://github.com/anthropics/impeccable | MIT |
| Agency Agents | https://github.com/anthropics/agency-agents | MIT |
| Claude HUD | https://github.com/anthropics/claude-hud | MIT |
| MCP Memory Server | https://github.com/anthropics/mcp-memory | MIT |
| last30days-skill | https://github.com/mvanhorn/last30days-skill | MIT |

All trademarks belong to their respective owners. This installer does not modify
the original source code of any bundled component.
ATTR_EOF
  success "ATTRIBUTION.md written"

  # Copy license files from this repo
  mkdir -p "$CLAUDE_HOME/licenses"
  if [[ -d "$SCRIPT_DIR/licenses" ]]; then
    local count=0
    for f in "$SCRIPT_DIR/licenses/"*; do
      if [[ -f "$f" ]]; then
        cp "$f" "$CLAUDE_HOME/licenses/"
        count=$((count + 1))
      fi
    done
    if [[ $count -gt 0 ]]; then
      success "Copied $count license file(s)"
    fi
  fi

  # Also grab LICENSE from cloned repos if available
  for repo_dir in "$TEMP_DIR"/*/; do
    if [[ -f "${repo_dir}LICENSE" ]]; then
      local name
      name="$(basename "$repo_dir")"
      cp "${repo_dir}LICENSE" "$CLAUDE_HOME/licenses/${name}-LICENSE"
    elif [[ -f "${repo_dir}LICENSE.md" ]]; then
      local name
      name="$(basename "$repo_dir")"
      cp "${repo_dir}LICENSE.md" "$CLAUDE_HOME/licenses/${name}-LICENSE.md"
    fi
  done
  success "License files collected"
}

# ── Manifest ──────────────────────────────────────────────────────────
write_manifest() {
  header "Writing manifest"

  local roles_json
  roles_json="$(printf '%s\n' "${SELECTED_ROLES[@]}" | \
    awk 'BEGIN{printf "["} NR>1{printf ","} {printf "\"%s\"",$0} END{printf "]"}')"

  local layers_json
  layers_json="$(printf '%s\n' "${MANIFEST_LAYERS[@]}" | \
    awk 'BEGIN{printf "["} NR>1{printf ","} {printf "\"%s\"",$0} END{printf "]"}')"

  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")"

  cat > "$CLAUDE_HOME/igsl-manifest.json" <<MANIFEST_EOF
{
  "installer": "igsl-claude-setup",
  "version": "1.0.0",
  "installedAt": "$ts",
  "os": "$OS",
  "claudeHome": "$CLAUDE_HOME",
  "roles": $roles_json,
  "layers": $layers_json
}
MANIFEST_EOF
  success "Manifest written to $CLAUDE_HOME/igsl-manifest.json"
}

# ── Smoke Test ────────────────────────────────────────────────────────
run_smoke_test() {
  header "Smoke Test"

  local passed=0
  local failed=0

  check_item() {
    local label="$1"
    local path="$2"
    if [[ -e "$path" ]]; then
      success "$label exists"
      passed=$((passed + 1))
    else
      warn "$label missing: $path"
      failed=$((failed + 1))
    fi
  }

  check_item "CLAUDE_HOME directory"       "$CLAUDE_HOME"
  check_item "skills/ directory"           "$CLAUDE_HOME/skills"
  check_item "scripts/ directory"          "$CLAUDE_HOME/scripts"
  check_item "ATTRIBUTION.md"             "$CLAUDE_HOME/ATTRIBUTION.md"
  check_item "igsl-manifest.json"         "$CLAUDE_HOME/igsl-manifest.json"
  check_item "licenses/ directory"        "$CLAUDE_HOME/licenses"
  check_item "settings.json"             "$CLAUDE_HOME/settings.json"

  if [[ -f "$CLAUDE_HOME/CLAUDE.md" ]]; then
    check_item "CLAUDE.md"               "$CLAUDE_HOME/CLAUDE.md"
  fi

  echo ""
  if [[ "$failed" -eq 0 ]]; then
    success "All $passed checks passed"
  else
    warn "$passed passed, $failed warnings"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────
main() {
  echo ""
  printf "${BOLD}${CYAN}"
  echo "╔══════════════════════════════════════════════╗"
  echo "║        IGSL Claude Setup Installer           ║"
  echo "╚══════════════════════════════════════════════╝"
  printf "${NC}\n"

  detect_os
  info "Detected OS: $OS"

  set_claude_home
  mkdir -p "$CLAUDE_HOME"

  TEMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t igsl)"
  info "Temp directory: $TEMP_DIR"

  check_prerequisites
  select_roles

  install_layer0_ecc
  install_layer1_methodology
  install_layer2_research
  install_layer3_agents
  install_layer4_hud
  install_layer5_memory
  install_layer6_custom
  generate_attribution
  write_manifest
  run_smoke_test

  echo ""
  printf "${BOLD}${GREEN}"
  echo "╔══════════════════════════════════════════════╗"
  echo "║          Installation Complete!              ║"
  echo "╚══════════════════════════════════════════════╝"
  printf "${NC}\n"
  info "CLAUDE_HOME: $CLAUDE_HOME"
  info "Roles:       ${SELECTED_ROLES[*]}"
  info "Layers:      ${MANIFEST_LAYERS[*]}"
  echo ""
}

main "$@"
