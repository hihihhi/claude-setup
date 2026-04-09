#Requires -Version 5.1
<#
.SYNOPSIS
  Claude Code Setup Installer (PowerShell — Windows native)

.DESCRIPTION
  Installs a curated Claude Code environment with role-based layers.
  Equivalent to install.sh for Windows PowerShell users.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$TempDir = $null
$ManifestLayers = [System.Collections.Generic.List[string]]::new()
$SelectedRoles = [System.Collections.Generic.List[string]]::new()
$ClaudeHome = ''

# ── Logging helpers ───────────────────────────────────────────────────
function Write-Info    { param([string]$Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Msg) Write-Host "[OK]    $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "[ERR]   $Msg" -ForegroundColor Red }
function Write-Header  { param([string]$Msg) Write-Host "`n-- $Msg --" -ForegroundColor White }

# ── Cleanup ───────────────────────────────────────────────────────────
function Invoke-Cleanup {
    if ($TempDir -and (Test-Path $TempDir)) {
        Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    }
}

# ── Set CLAUDE_HOME ───────────────────────────────────────────────────
function Set-ClaudeHome {
    $script:ClaudeHome = Join-Path $env:USERPROFILE '.claude'
    Write-Info "CLAUDE_HOME = $script:ClaudeHome"
}

# ── Dependency installation ───────────────────────────────────────────
# Checks each required/optional tool and installs missing ones via winget.
# Defaults: Y for required tools (Node, Python, jq), N for optional (LaTeX, Obsidian).
function Install-Dependencies {
    Write-Header 'Installing Dependencies'

    # ── Git (hard requirement) ──
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Err 'git is required but not found. Install from: https://git-scm.com/download/win'
        exit 1
    } else {
        Write-Ok "git found: $(git --version)"
    }

    # ── Node.js ──
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Warn 'Node.js not found'
        $yn = Read-Host '  Install Node.js LTS now? [Y/n]'
        if ([string]::IsNullOrWhiteSpace($yn) -or $yn -match '^[Yy]') {
            Write-Info 'Installing Node.js LTS via winget...'
            try {
                winget install OpenJS.NodeJS.LTS `
                    --accept-package-agreements --accept-source-agreements | Out-Null
                Write-Ok 'Node.js installed'
            } catch {
                Write-Warn "winget failed: $_. Install from https://nodejs.org"
            }
        }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            Write-Err 'Node.js still not found. Install it and re-run.'
            exit 1
        }
    } else {
        Write-Ok "node found: $(node --version)"
    }

    # npx ships with Node >= 5.2
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Write-Info 'Installing npx...'
        try { npm install -g npx | Out-Null } catch { Write-Warn "Could not install npx: $_" }
    } else {
        Write-Ok 'npx found'
    }

    # ── Claude Code CLI ──
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Warn 'Claude Code CLI not found'
        $yn = Read-Host '  Install Claude Code CLI now? [Y/n]'
        if ([string]::IsNullOrWhiteSpace($yn) -or $yn -match '^[Yy]') {
            Write-Info 'Installing @anthropic-ai/claude-code...'
            try {
                npm install -g '@anthropic-ai/claude-code'
                Write-Ok 'Claude Code CLI installed'
            } catch {
                Write-Warn "Install failed: $_. Run: npm install -g @anthropic-ai/claude-code"
            }
        }
    } else {
        Write-Ok 'claude: found'
    }

    # ── Python 3 (required for memory + security hooks) ──
    $hasPython = (Get-Command python3 -ErrorAction SilentlyContinue) -or
                 (Get-Command python  -ErrorAction SilentlyContinue)
    if (-not $hasPython) {
        Write-Warn 'Python not found (required for memory hooks)'
        $yn = Read-Host '  Install Python 3 now? [Y/n]'
        if ([string]::IsNullOrWhiteSpace($yn) -or $yn -match '^[Yy]') {
            Write-Info 'Installing Python 3 via winget...'
            try {
                winget install Python.Python.3 `
                    --accept-package-agreements --accept-source-agreements | Out-Null
                Write-Ok 'Python installed'
            } catch {
                Write-Warn "winget failed: $_. Install from https://python.org"
            }
        }
    } else {
        Write-Ok 'Python found'
    }

    # ── uv (recommended Python package manager) ──
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        Write-Warn 'uv not found (recommended Python package manager)'
        $yn = Read-Host '  Install uv now? [Y/n]'
        if ([string]::IsNullOrWhiteSpace($yn) -or $yn -match '^[Yy]') {
            Write-Info 'Installing uv via winget...'
            try {
                winget install astral-sh.uv `
                    --accept-package-agreements --accept-source-agreements | Out-Null
                Write-Ok 'uv installed'
            } catch {
                Write-Warn "winget failed: $_"
                try {
                    pip install uv | Out-Null
                    Write-Ok 'uv installed via pip'
                } catch {
                    Write-Warn "Could not install uv. See https://github.com/astral-sh/uv"
                }
            }
        }
    } else {
        Write-Ok "uv found: $(uv --version)"
    }

    # ── jq (required by HUD status line) ──
    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
        Write-Warn 'jq not found (required by HUD status line)'
        $yn = Read-Host '  Install jq now? [Y/n]'
        if ([string]::IsNullOrWhiteSpace($yn) -or $yn -match '^[Yy]') {
            Write-Info 'Installing jq via winget...'
            try {
                winget install stedolan.jq `
                    --accept-package-agreements --accept-source-agreements | Out-Null
                Write-Ok 'jq installed'
            } catch {
                Write-Warn "winget failed: $_. Install from https://jqlang.github.io/jq/"
            }
        }
    } else {
        Write-Ok "jq found: $(jq --version)"
    }

    # ── LaTeX (optional — needed for PDF/docs skills) ──
    $hasLatex = (Get-Command pdflatex -ErrorAction SilentlyContinue) -or
                (Get-Command xelatex  -ErrorAction SilentlyContinue)
    if (-not $hasLatex) {
        Write-Warn 'LaTeX not found (optional -- needed for PDF generation skills)'
        $yn = Read-Host '  Install MiKTeX? (~1-2 GB download) [y/N]'
        if ($yn -match '^[Yy]') {
            Write-Info 'Installing MiKTeX via winget...'
            try {
                winget install MiKTeX.MiKTeX `
                    --accept-package-agreements --accept-source-agreements | Out-Null
                Write-Ok 'MiKTeX installed'
            } catch {
                Write-Warn "winget failed: $_. Install from https://miktex.org/download"
            }
        } else {
            Write-Info 'LaTeX skipped -- /pdf and /docx skills will not work without it'
        }
    } else {
        Write-Ok 'LaTeX found'
    }

    # ── Obsidian (optional — knowledge base integration) ──
    if (-not (Get-Command obsidian -ErrorAction SilentlyContinue)) {
        Write-Warn 'Obsidian not found (optional -- knowledge base integration)'
        $yn = Read-Host '  Install Obsidian? [y/N]'
        if ($yn -match '^[Yy]') {
            Write-Info 'Installing Obsidian via winget...'
            try {
                winget install Obsidian.Obsidian `
                    --accept-package-agreements --accept-source-agreements | Out-Null
                Write-Ok 'Obsidian installed'
            } catch {
                Write-Warn "winget failed: $_. Install from https://obsidian.md/download"
            }
        } else {
            Write-Info 'Obsidian skipped'
        }
    } else {
        Write-Ok 'Obsidian found'
    }
}

# ── Role Selection ────────────────────────────────────────────────────
function Select-Roles {
    Write-Header 'Select roles to install'
    Write-Host ''
    Write-Host '  [1] Full-Stack Developer'
    Write-Host '  [2] Backend Developer'
    Write-Host '  [3] Frontend Developer / Designer'
    Write-Host '  [4] Researcher / Analyst'
    Write-Host '  [5] Product Manager'
    Write-Host '  [6] Data Scientist / ML Engineer'
    Write-Host '  [7] DevOps / SRE'
    Write-Host '  [8] All (install everything)'
    Write-Host ''

    $roleInput = Read-Host 'Enter selections (comma-separated, e.g. 1,3,6)'
    if ([string]::IsNullOrWhiteSpace($roleInput)) {
        Write-Warn 'No selection made -- defaulting to [8] All'
        $roleInput = '8'
    }

    $choices = $roleInput -split ',' | ForEach-Object { $_.Trim() }
    foreach ($choice in $choices) {
        switch ($choice) {
            '1' { $script:SelectedRoles.Add('fullstack')   }
            '2' { $script:SelectedRoles.Add('backend')     }
            '3' { $script:SelectedRoles.Add('frontend')    }
            '4' { $script:SelectedRoles.Add('researcher')  }
            '5' { $script:SelectedRoles.Add('pm')          }
            '6' { $script:SelectedRoles.Add('datascience') }
            '7' { $script:SelectedRoles.Add('devops')      }
            '8' {
                $script:SelectedRoles.Clear()
                @('fullstack','backend','frontend','researcher',
                  'pm','datascience','devops') | ForEach-Object {
                    $script:SelectedRoles.Add($_)
                }
            }
            default { Write-Warn "Unknown selection: $choice -- skipping" }
        }
    }

    if ($script:SelectedRoles.Count -eq 0) {
        Write-Err 'No valid roles selected. Exiting.'
        exit 1
    }

    Write-Ok "Selected roles: $($script:SelectedRoles -join ', ')"
}

function Test-HasRole {
    param([string]$Role)
    return $script:SelectedRoles -contains $Role
}

function Test-HasAnyRole {
    param([string[]]$Roles)
    foreach ($r in $Roles) {
        if ($script:SelectedRoles -contains $r) { return $true }
    }
    return $false
}

# ── Invoke-NpxSafe: run npx, swallow errors if package not found ─────
function Invoke-NpxSafe {
    param([string[]]$Args, [string]$Label)
    try {
        $output = & npx @Args 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "$Label returned non-zero exit code"
        } else {
            Write-Ok $Label
        }
    } catch {
        Write-Warn "$Label failed: $_"
    }
}

# ── Layer 0: ECC ──────────────────────────────────────────────────────
function Install-Layer0-ECC {
    Write-Header 'Layer 0: Everything Claude Code'

    $eccSkill = Join-Path $ClaudeHome 'skills\everything-claude-code.md'
    $eccDir   = Join-Path $ClaudeHome 'skills\everything-claude-code'

    if ((Test-Path $eccSkill) -or (Test-Path $eccDir)) {
        Write-Warn 'ECC already installed -- skipping'
    } else {
        Write-Info 'Installing everything-claude-code...'
        Invoke-NpxSafe -Args @('everything-claude-code', 'install') `
                       -Label 'ECC installed'
    }
    $script:ManifestLayers.Add('ecc')
}

# ── Layer 1: Methodology Skills ───────────────────────────────────────
function Install-Layer1-Methodology {
    Write-Header 'Layer 1: Methodology Skills'

    $skillsDir = Join-Path $ClaudeHome 'skills'
    if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null }

    # Clone superpowers
    $superpowersDir = Join-Path $TempDir 'superpowers'
    if (-not (Test-Path $superpowersDir)) {
        Write-Info 'Cloning claude-code-superpowers...'
        try {
            git clone --depth 1 https://github.com/anthropics/claude-code-superpowers.git $superpowersDir 2>&1 | Out-Null
            Write-Ok 'Superpowers cloned'
        } catch {
            Write-Warn "Could not clone superpowers -- skipping: $_"
        }
    }

    $superpowersSkills = Join-Path $superpowersDir 'skills'
    if (Test-Path $superpowersSkills) {
        Copy-Item -Path "$superpowersSkills\*" -Destination $skillsDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Ok 'Superpowers skills copied'
    }

    # Core methodology skills
    Write-Info 'Installing TDD and PRD-to-plan skills...'
    Invoke-NpxSafe -Args @('skills', 'add', 'mattpocock/skills/tdd', 'mattpocock/skills/prd-to-plan') `
                   -Label 'TDD + PRD-to-plan skills installed'

    # Frontend: impeccable
    if (Test-HasAnyRole -Roles @('frontend', 'fullstack')) {
        Write-Info 'Installing impeccable skills for frontend role...'
        Invoke-NpxSafe -Args @('skills', 'add',
            'anthropics/impeccable/audit',
            'anthropics/impeccable/critique',
            'anthropics/impeccable/polish',
            'anthropics/impeccable/typeset') `
            -Label 'Impeccable skills installed'
    }

    Write-Ok 'Layer 1 complete'
    $script:ManifestLayers.Add('methodology')
}

# ── Layer 2: Research Skills ──────────────────────────────────────────
function Install-Layer2-Research {
    Write-Header 'Layer 2: Research Skills'

    if (Test-HasAnyRole -Roles @('researcher', 'datascience')) {
        Write-Info 'Installing research skills...'
        Invoke-NpxSafe -Args @('skills', 'add', 'mvanhorn/last30days-skill') `
                       -Label 'Research skills installed'
    } else {
        Write-Info 'No researcher/data-science role selected -- skipping'
    }
    $script:ManifestLayers.Add('research')
}

# ── Layer 3: Agents ───────────────────────────────────────────────────
function Install-Layer3-Agents {
    Write-Header 'Layer 3: Agents'

    $agentsDir = Join-Path $TempDir 'agency-agents'
    Write-Info 'Cloning agency-agents...'
    try {
        git clone --depth 1 https://github.com/anthropics/agency-agents.git $agentsDir 2>&1 | Out-Null
    } catch {
        Write-Warn "Could not clone agency-agents -- skipping: $_"
        $script:ManifestLayers.Add('agents')
        return
    }

    $installScript = Join-Path $agentsDir 'install.sh'
    $installPs1    = Join-Path $agentsDir 'install.ps1'

    if (Test-Path $installPs1) {
        Write-Info "Running agency-agents PowerShell installer (roles: $($SelectedRoles -join ', '))..."
        try {
            $roleArgs = $SelectedRoles | ForEach-Object { "--role"; $_ }
            & powershell -ExecutionPolicy Bypass -File $installPs1 @roleArgs 2>&1 | Out-Null
            Write-Ok 'Agents installed'
        } catch {
            Write-Warn "agency-agents install returned error: $_"
        }
    } elseif (Test-Path $installScript) {
        # Try running via bash (Git Bash)
        $bash = Get-Command bash -ErrorAction SilentlyContinue
        if ($bash) {
            Write-Info 'Running agency-agents install.sh via bash...'
            $roleArgs = ($SelectedRoles | ForEach-Object { "--role $_" }) -join ' '
            try {
                & bash $installScript $roleArgs 2>&1 | Out-Null
                Write-Ok 'Agents installed via bash'
            } catch {
                Write-Warn "agency-agents bash install returned error: $_"
            }
        } else {
            Write-Warn 'No PowerShell installer found and bash not available'
        }
    } else {
        # Fallback: copy agent files directly
        $agentsMdDir = Join-Path $agentsDir 'agents'
        $destAgents  = Join-Path $ClaudeHome 'agents'
        if (Test-Path $agentsMdDir) {
            if (-not (Test-Path $destAgents)) {
                New-Item -ItemType Directory -Path $destAgents -Force | Out-Null
            }
            Copy-Item -Path "$agentsMdDir\*" -Destination $destAgents -Recurse -Force -ErrorAction SilentlyContinue
            Write-Ok "Agent files copied to $destAgents"
        } else {
            Write-Warn 'No agents directory found in agency-agents repo'
        }
    }
    $script:ManifestLayers.Add('agents')
}

# ── Layer 4: HUD ──────────────────────────────────────────────────────
# Writes the statusLine config to settings.json directly (no separate package).
# The command reads context JSON piped by Claude Code and prints a formatted
# status string: user:path branch* ctx:% model time [todos:N]
function Install-Layer4-HUD {
    Write-Header 'Layer 4: HUD status line'

    $settingsFile = Join-Path $ClaudeHome 'settings.json'
    if (-not (Test-Path $settingsFile)) {
        '{}' | Set-Content -Path $settingsFile -Encoding UTF8
    }

    $raw = Get-Content -Raw $settingsFile
    if ($raw -match '"statusLine"') {
        Write-Info 'statusLine already configured -- skipping'
        $script:ManifestLayers.Add('hud')
        return
    }

    Write-Info 'Writing statusLine config to settings.json...'

    # Use Python to merge statusLine into settings.json (same command as install.sh)
    $pythonScript = @'
import json, sys
file = sys.argv[1]
with open(file, encoding='utf-8') as f:
    cfg = json.load(f)
cmd = (
    "input=$(cat); user=$(whoami); "
    "cwd=$(echo \"$input\" | jq -r '.workspace.current_dir' | sed \"s|$HOME|~|g\"); "
    "model=$(echo \"$input\" | jq -r '.model.display_name'); "
    "time=$(date +%H:%M); "
    "remaining=$(echo \"$input\" | jq -r '.context_window.remaining_percentage // empty'); "
    "transcript=$(echo \"$input\" | jq -r '.transcript_path'); "
    "todo_count=$([ -f \"$transcript\" ] && grep -c '\"type\":\"todo\"' \"$transcript\" 2>/dev/null || echo 0); "
    "cd \"$(echo \"$input\" | jq -r '.workspace.current_dir')\" 2>/dev/null; "
    "branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ''); "
    "status=''; "
    "[ -n \"$branch\" ] && { [ -n \"$(git status --porcelain 2>/dev/null)\" ] && status='*'; }; "
    "B='\\033[38;2;30;102;245m'; G='\\033[38;2;64;160;43m'; Y='\\033[38;2;223;142;29m'; "
    "M='\\033[38;2;136;57;239m'; C='\\033[38;2;23;146;153m'; R='\\033[0m'; T='\\033[38;2;76;79;105m'; "
    "printf \"${C}${user}${R}:${B}${cwd}${R}\"; "
    "[ -n \"$branch\" ] && printf \" ${G}${branch}${Y}${status}${R}\"; "
    "[ -n \"$remaining\" ] && printf \" ${M}ctx:${remaining}%%${R}\"; "
    "printf \" ${T}${model}${R} ${Y}${time}${R}\"; "
    "[ \"$todo_count\" -gt 0 ] && printf \" ${C}todos:${todo_count}${R}\"; echo"
)
cfg["statusLine"] = {"type": "command", "command": cmd}
with open(file, "w", encoding='utf-8') as f:
    json.dump(cfg, f, indent=2)
'@

    $tmpPy = Join-Path ([System.IO.Path]::GetTempPath()) 'hud_merge.py'
    $pythonScript | Set-Content -Path $tmpPy -Encoding UTF8

    $python = Get-Command python3 -ErrorAction SilentlyContinue
    if (-not $python) { $python = Get-Command python -ErrorAction SilentlyContinue }

    if ($python) {
        try {
            & $python.Source $tmpPy $settingsFile
            Write-Ok 'HUD status line configured'
        } catch {
            Write-Warn "Could not configure HUD: $_"
        }
    } else {
        Write-Warn 'Python not available -- HUD skipped. Re-run after installing Python.'
    }

    Remove-Item $tmpPy -ErrorAction SilentlyContinue
    Write-Ok 'Layer 4 complete'
    $script:ManifestLayers.Add('hud')
}

# ── Layer 5: Memory System ────────────────────────────────────────────
# Installs hook scripts and configures settings.json with:
#   - MCP memory server (@modelcontextprotocol/server-memory)
#   - UserPromptSubmit hook (TF-IDF memory injection)
#   - PreToolUse hooks (bash-guard, scan-secrets)
#   - Stop hook (update-state)
#   - SessionStart hook (inject session state)
#
# Windows MCP fix: npx is a .cmd batch file on Windows and cannot be spawned
# directly. All MCP servers use cmd /c npx to route through cmd.exe.
function Install-Layer5-Memory {
    Write-Header 'Layer 5: Memory System & Security Hooks'

    $scriptsDir = Join-Path $ClaudeHome 'scripts'
    if (-not (Test-Path $scriptsDir)) {
        New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    }

    # Copy hook scripts from this repo
    $repoScripts = Join-Path $ScriptDir 'scripts'
    if (Test-Path $repoScripts) {
        $files = Get-ChildItem -Path $repoScripts -File -ErrorAction SilentlyContinue
        if ($files -and $files.Count -gt 0) {
            $files | Copy-Item -Destination $scriptsDir -Force
            Write-Ok "Copied $($files.Count) script(s) to $scriptsDir"
        } else {
            Write-Info 'No scripts found in scripts/ (directory is empty)'
        }
    } else {
        Write-Warn 'No scripts/ directory in repo -- skipping script copy'
    }

    # Create memory directory and entities file for MCP server
    $memoryDir = Join-Path $ClaudeHome 'memory'
    if (-not (Test-Path $memoryDir)) {
        New-Item -ItemType Directory -Path $memoryDir -Force | Out-Null
    }
    $entitiesFile = Join-Path $memoryDir 'entities.jsonl'
    if (-not (Test-Path $entitiesFile)) {
        '' | Set-Content -Path $entitiesFile -Encoding UTF8
    }

    # Use Python to update settings.json (handles complex JSON merging reliably)
    $settingsFile = Join-Path $ClaudeHome 'settings.json'
    if (-not (Test-Path $settingsFile)) {
        '{}' | Set-Content -Path $settingsFile -Encoding UTF8
    }

    $pythonScript = @"
import json, sys
file = r'$($settingsFile.Replace('\', '\\'))'
entities = r'$($entitiesFile.Replace('\', '\\'))'
with open(file, encoding='utf-8') as f:
    cfg = json.load(f)

# MCP memory server — Windows: cmd /c npx to resolve .cmd batch file
cfg.setdefault('mcpServers', {})
if 'memory' not in cfg['mcpServers']:
    cfg['mcpServers']['memory'] = {
        'type': 'stdio',
        'command': 'cmd',
        'args': ['/c', 'npx', '-y', '@modelcontextprotocol/server-memory'],
        'env': {'MEMORY_FILE_PATH': entities}
    }

# Hooks
if 'hooks' not in cfg:
    cfg['hooks'] = {
        'SessionStart': [{'matcher': '', 'hooks': [{'type': 'command',
            'command': 'cat ~/.claude/projects/$(basename $PWD 2>/dev/null)/state.md 2>/dev/null || true',
            'timeout': 5000}]}],
        'UserPromptSubmit': [{'matcher': '', 'hooks': [{'type': 'command',
            'command': 'python3 ~/.claude/scripts/memory-search.py 2>/dev/null || true',
            'timeout': 3000}]}],
        'PreToolUse': [
            {'matcher': 'Bash', 'hooks': [{'type': 'command',
                'command': 'python3 ~/.claude/scripts/bash-guard.py',
                'timeout': 2000}]},
            {'matcher': 'Write|Edit', 'hooks': [{'type': 'command',
                'command': 'python3 ~/.claude/scripts/scan-secrets.py',
                'timeout': 2000}]}
        ],
        'Stop': [{'matcher': '', 'hooks': [{'type': 'command',
            'command': 'python3 ~/.claude/scripts/update-state.py',
            'timeout': 3000}]}]
    }

with open(file, 'w', encoding='utf-8') as f:
    json.dump(cfg, f, indent=2)
"@

    $tmpPy = Join-Path ([System.IO.Path]::GetTempPath()) 'memory_merge.py'
    $pythonScript | Set-Content -Path $tmpPy -Encoding UTF8

    $python = Get-Command python3 -ErrorAction SilentlyContinue
    if (-not $python) { $python = Get-Command python -ErrorAction SilentlyContinue }

    if ($python) {
        try {
            & $python.Source $tmpPy
            Write-Ok 'MCP memory server and hooks configured in settings.json'
        } catch {
            Write-Warn "Could not update settings.json: $_"
        }
    } else {
        Write-Warn 'Python not available -- memory/hooks config skipped. Re-run after installing Python.'
    }

    Remove-Item $tmpPy -ErrorAction SilentlyContinue
    $script:ManifestLayers.Add('memory')
}

# ── Layer 6: Custom Templates ─────────────────────────────────────────
function Install-Layer6-Custom {
    Write-Header 'Layer 6: Custom Templates'

    # CLAUDE.md template
    $templateMd = Join-Path $ScriptDir 'config\CLAUDE.md'
    if (Test-Path $templateMd) {
        $destMd = Join-Path $ClaudeHome 'CLAUDE.md'
        if (Test-Path $destMd) {
            Write-Warn 'CLAUDE.md already exists -- backing up to CLAUDE.md.bak'
            Copy-Item $destMd "$destMd.bak" -Force
        }
        Copy-Item $templateMd $destMd -Force
        Write-Ok 'CLAUDE.md template installed'
    } else {
        Write-Info 'No CLAUDE.md template found in config/ -- skipping'
    }

    # Role overlays
    $rolesSource = Join-Path $ScriptDir 'config\roles'
    if (Test-Path $rolesSource) {
        $rolesDest = Join-Path $ClaudeHome 'config\roles'
        if (-not (Test-Path $rolesDest)) {
            New-Item -ItemType Directory -Path $rolesDest -Force | Out-Null
        }
        $files = Get-ChildItem -Path $rolesSource -File -ErrorAction SilentlyContinue
        if ($files -and $files.Count -gt 0) {
            $files | Copy-Item -Destination $rolesDest -Force
            Write-Ok "Copied $($files.Count) role overlay(s)"
        } else {
            Write-Info 'No role overlays in config/roles/ (directory is empty)'
        }
    }

    # Team templates
    $teamsSource = Join-Path $ScriptDir 'teams\templates'
    if (Test-Path $teamsSource) {
        $teamsDest = Join-Path $ClaudeHome 'teams\templates'
        if (-not (Test-Path $teamsDest)) {
            New-Item -ItemType Directory -Path $teamsDest -Force | Out-Null
        }
        $files = Get-ChildItem -Path $teamsSource -File -ErrorAction SilentlyContinue
        if ($files -and $files.Count -gt 0) {
            $files | Copy-Item -Destination $teamsDest -Force
            Write-Ok "Copied $($files.Count) team template(s)"
        } else {
            Write-Info 'No team templates found (directory is empty)'
        }
    }

    $script:ManifestLayers.Add('custom')
}

# ── Layer 7: Skills ───────────────────────────────────────────────────
# Copies skills from this repo's skills/ directory into ~/.claude/skills/
function Install-Layer7-Skills {
    Write-Header 'Layer 7: Skills'

    $skillsDir = Join-Path $ClaudeHome 'skills'
    if (-not (Test-Path $skillsDir)) {
        New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    }

    $repoSkills = Join-Path $ScriptDir 'skills'
    if (Test-Path $repoSkills) {
        $skillDirs = Get-ChildItem -Path $repoSkills -Directory -ErrorAction SilentlyContinue
        $count = 0
        foreach ($sd in $skillDirs) {
            $dest = Join-Path $skillsDir $sd.Name
            if (-not (Test-Path $dest)) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
            }
            Copy-Item -Path "$($sd.FullName)\*" -Destination $dest -Recurse -Force `
                -ErrorAction SilentlyContinue
            Write-Info "Installed skill: $($sd.Name)"
            $count++
        }
        if ($count -gt 0) { Write-Ok "Installed $count skill(s)" }
    } else {
        Write-Warn 'No skills/ directory in repo -- skipping'
    }

    Write-Ok 'Layer 7 complete'
    $script:ManifestLayers.Add('skills')
}

# ── Attribution & Licenses ────────────────────────────────────────────
function New-Attribution {
    Write-Header 'Generating attribution'

    $attrPath = Join-Path $ClaudeHome 'ATTRIBUTION.md'
    $attrContent = @'
# Claude Code Setup -- Attribution

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
'@
    Set-Content -Path $attrPath -Value $attrContent -Encoding UTF8
    Write-Ok 'ATTRIBUTION.md written'

    # Copy license files from repo
    $licensesDir = Join-Path $ClaudeHome 'licenses'
    if (-not (Test-Path $licensesDir)) {
        New-Item -ItemType Directory -Path $licensesDir -Force | Out-Null
    }

    $repoLicenses = Join-Path $ScriptDir 'licenses'
    if (Test-Path $repoLicenses) {
        $files = Get-ChildItem -Path $repoLicenses -File -ErrorAction SilentlyContinue
        if ($files -and $files.Count -gt 0) {
            $files | Copy-Item -Destination $licensesDir -Force
            Write-Ok "Copied $($files.Count) license file(s)"
        }
    }

    # Grab LICENSE from cloned repos
    if ($TempDir -and (Test-Path $TempDir)) {
        Get-ChildItem -Path $TempDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $licFile = Join-Path $_.FullName 'LICENSE'
            $licMd   = Join-Path $_.FullName 'LICENSE.md'
            if (Test-Path $licFile) {
                Copy-Item $licFile (Join-Path $licensesDir "$($_.Name)-LICENSE") -Force
            } elseif (Test-Path $licMd) {
                Copy-Item $licMd (Join-Path $licensesDir "$($_.Name)-LICENSE.md") -Force
            }
        }
    }
    Write-Ok 'License files collected'
}

# ── Manifest ──────────────────────────────────────────────────────────
function Write-Manifest {
    Write-Header 'Writing manifest'

    $manifest = [PSCustomObject]@{
        installer   = 'claude-setup'
        version     = '1.2.0'
        installedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        os          = 'windows'
        claudeHome  = $ClaudeHome
        roles       = @($SelectedRoles)
        layers      = @($ManifestLayers)
    }

    $manifestPath = Join-Path $ClaudeHome 'claude-setup-manifest.json'
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding UTF8
    Write-Ok "Manifest written to $manifestPath"
}

# ── Smoke Test ────────────────────────────────────────────────────────
function Invoke-SmokeTest {
    Write-Header 'Smoke Test'

    $passed = 0
    $failed = 0

    function Test-Item {
        param([string]$Label, [string]$Path)
        if (Test-Path $Path) {
            Write-Ok "$Label exists"
            $script:passed++
        } else {
            Write-Warn "$Label missing: $Path"
            $script:failed++
        }
    }

    # Use script-scoped counters
    $script:passed = 0
    $script:failed = 0

    Test-Item 'CLAUDE_HOME directory'   $ClaudeHome
    Test-Item 'skills/ directory'       (Join-Path $ClaudeHome 'skills')
    Test-Item 'scripts/ directory'      (Join-Path $ClaudeHome 'scripts')
    Test-Item 'ATTRIBUTION.md'         (Join-Path $ClaudeHome 'ATTRIBUTION.md')
    Test-Item 'claude-setup-manifest.json'     (Join-Path $ClaudeHome 'claude-setup-manifest.json')
    Test-Item 'licenses/ directory'    (Join-Path $ClaudeHome 'licenses')
    Test-Item 'settings.json'          (Join-Path $ClaudeHome 'settings.json')

    $claudeMd = Join-Path $ClaudeHome 'CLAUDE.md'
    if (Test-Path $claudeMd) {
        Test-Item 'CLAUDE.md' $claudeMd
    }

    Write-Host ''
    if ($script:failed -eq 0) {
        Write-Ok "All $($script:passed) checks passed"
    } else {
        Write-Warn "$($script:passed) passed, $($script:failed) warnings"
    }
}

# ── Main ──────────────────────────────────────────────────────────────
function Main {
    Write-Host ''
    Write-Host '+==============================================+' -ForegroundColor Cyan
    Write-Host '|        Claude Code Setup Installer           |' -ForegroundColor Cyan
    Write-Host '+==============================================+' -ForegroundColor Cyan
    Write-Host ''

    Write-Info 'Detected OS: windows'

    Set-ClaudeHome
    if (-not (Test-Path $ClaudeHome)) {
        New-Item -ItemType Directory -Path $ClaudeHome -Force | Out-Null
    }

    $script:TempDir = Join-Path ([System.IO.Path]::GetTempPath()) "claude-setup-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TempDir -Force | Out-Null
    Write-Info "Temp directory: $script:TempDir"

    try {
        Install-Dependencies
        Select-Roles

        Install-Layer0-ECC
        Install-Layer1-Methodology
        Install-Layer2-Research
        Install-Layer3-Agents
        Install-Layer4-HUD
        Install-Layer5-Memory
        Install-Layer6-Custom
        Install-Layer7-Skills
        New-Attribution
        Write-Manifest
        Invoke-SmokeTest

        Write-Host ''
        Write-Host '+==============================================+' -ForegroundColor Green
        Write-Host '|          Installation Complete!              |' -ForegroundColor Green
        Write-Host '+==============================================+' -ForegroundColor Green
        Write-Host ''
        Write-Info "CLAUDE_HOME: $ClaudeHome"
        Write-Info "Roles:       $($SelectedRoles -join ', ')"
        Write-Info "Layers:      $($ManifestLayers -join ', ')"
        Write-Host ''
    } finally {
        Invoke-Cleanup
    }
}

Main
