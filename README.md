# Claude Code Workspace Harness

A portable configuration and installer harness for Anthropic's Claude Code that assembles role overlays, team templates, local hooks, and persistent-memory utilities. No headline performance result; the deliverable is the harness.

## Status & honesty

Active configuration repository. The installers target `~/.claude` (or `%USERPROFILE%\.claude`) and may download upstream packages and modify that profile; they were not executed during repository verification. Measured repository checks are three deterministic integrity tests, Bash syntax validation for three shell scripts, PowerShell parsing for `install.ps1`, and Pyright standard-mode checking of the Python hook scripts and `docs/generate_report.py`; they do not measure model quality, latency, reliability, or security effectiveness.

## Architecture

- `install.sh` and `install.ps1` detect the host environment, collect a role selection, assemble configuration layers, and write an installation manifest.
- `config/CLAUDE.md`, `config/roles/`, `rules/`, and `teams/templates/` provide the instruction, role-overlay, policy, and multi-agent workflow layers.
- `skills/` and `setup/SKILL.md` define reusable task workflows and setup entry points.
- `scripts/` supplies local hook utilities for memory lookup, command guarding, secret-pattern scanning, state updates, session logging, and health checks.
- `.github/workflows/integrity.yml` runs offline asset checks, Pyright, and shell/PowerShell syntax checks on pull requests.

## The interesting decision

The harness keeps operational instructions, role-specific overlays, and retrieved project memory in separate layers instead of placing all context in one prompt. That bounds always-loaded context and allows role-specific workflows, at the cost of more configuration files, hook dependencies, and installation complexity.

## Provenance

Anthropic's Claude Code is the upstream platform; it is not authored by this repository. `ATTRIBUTION.md` records bundled, adapted, pattern-derived, and excluded third-party components and their stated licenses. The repository includes an MIT `LICENSE`, but whether that license is sufficient for every bundled or derived artifact is **UNKNOWN**; review `ATTRIBUTION.md` and the included notices before redistribution or relicensing.

## Run it

Clone and run the non-destructive repository checks:

```bash
git clone https://github.com/hihihhi/claude-setup.git
cd claude-setup
python -m unittest discover -s tests -v
python -m pyright
bash -n install.sh
bash -n scripts/health-check.sh
bash -n scripts/sync-shared-memory.sh
```

On Windows PowerShell, validate the installer syntax without running it:

```powershell
$tokens = $errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
  (Join-Path (Get-Location) 'install.ps1'), [ref] $tokens, [ref] $errors
) | Out-Null
$errors
```

After reviewing the installer and accepting profile changes, run one installer interactively:

```bash
./install.sh
```

```powershell
.\install.ps1
```

## Limitations

- No independent end-to-end benchmark, user study, model-quality evaluation, latency measurement, or reliability measurement is recorded.
- The installer can fetch external packages and writes to the Claude Code user profile; its effects are environment-dependent.
- Hook behaviour relies on locally available Python, shell tooling, and the target Claude Code configuration format.
- Third-party provenance is documented but not independently re-audited here; license sufficiency is **UNKNOWN**.