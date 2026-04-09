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

# ── Prerequisite checks ──────────────────────────────────────────────
function Test-Prerequisites {
    Write-Header 'Checking prerequisites'
    $missing = 0

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Err 'git is not installed'
        $missing++
    } else {
        Write-Ok "git found: $(git --version)"
    }

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Err 'node is not installed'
        $missing++
    } else {
        Write-Ok "node found: $(node --version)"
    }

    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Write-Err 'npx is not installed'
        $missing++
    } else {
        Write-Ok 'npx found'
    }

    if ($missing -gt 0) {
        Write-Err 'Missing prerequisites. Install them and re-run.'
        exit 1
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
function Install-Layer4-HUD {
    Write-Header 'Layer 4: Claude HUD'

    Write-Info 'Installing claude-hud...'
    Invoke-NpxSafe -Args @('claude-hud', 'install') `
                   -Label 'Claude HUD installed'

    Write-Ok 'Layer 4 complete'
    $script:ManifestLayers.Add('hud')
}

# ── Layer 5: Memory System ────────────────────────────────────────────
function Install-Layer5-Memory {
    Write-Header 'Layer 5: Memory System'

    $scriptsDir = Join-Path $ClaudeHome 'scripts'
    if (-not (Test-Path $scriptsDir)) {
        New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    }

    # Copy memory scripts from this repo
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

    # Configure MCP memory server
    $settingsFile = Join-Path $ClaudeHome 'settings.json'
    if (Test-Path $settingsFile) {
        $settingsContent = Get-Content -Raw $settingsFile
        if ($settingsContent -match '"memory"') {
            Write-Info 'Memory MCP server already configured in settings.json'
        } else {
            Write-Info 'Adding memory MCP server to settings.json...'
            try {
                $cfg = $settingsContent | ConvertFrom-Json
                if (-not (Get-Member -InputObject $cfg -Name 'mcpServers' -MemberType NoteProperty)) {
                    $cfg | Add-Member -NotePropertyName 'mcpServers' -NotePropertyValue ([PSCustomObject]@{})
                }
                $memoryServer = [PSCustomObject]@{
                    command = 'npx'
                    args    = @('-y', '@anthropic/mcp-memory')
                }
                $cfg.mcpServers | Add-Member -NotePropertyName 'memory' -NotePropertyValue $memoryServer -Force
                $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsFile -Encoding UTF8
                Write-Ok 'Memory MCP server added to settings.json'
            } catch {
                Write-Warn "Could not update settings.json: $_"
            }
        }
    } else {
        Write-Info 'Creating settings.json with memory MCP server...'
        $newSettings = [PSCustomObject]@{
            mcpServers = [PSCustomObject]@{
                memory = [PSCustomObject]@{
                    command = 'npx'
                    args    = @('-y', '@anthropic/mcp-memory')
                }
            }
        }
        $newSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsFile -Encoding UTF8
        Write-Ok 'settings.json created'
    }

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
        version     = '1.0.0'
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
        Test-Prerequisites
        Select-Roles

        Install-Layer0-ECC
        Install-Layer1-Methodology
        Install-Layer2-Research
        Install-Layer3-Agents
        Install-Layer4-HUD
        Install-Layer5-Memory
        Install-Layer6-Custom
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
