## One sentence

This project provides a cross-platform Claude Code harness with role overlays, agent-team templates, persistent memory, and local security hooks.

## Result

No headline result. The repository records operating limits and configuration targets, but no benchmarked quality, latency, throughput, or reliability result.

## How it works

- A `/setup` skill detects the operating system and installs the selected role configuration.
- PowerShell and shell installers provide non-interactive Windows, macOS, and Linux paths.
- Role overlays and team templates separate research, implementation, testing, and review contexts.
- Python and shell hooks implement memory retrieval, secret-pattern checks, command guards, state updates, and health checks.
- `ATTRIBUTION.md` records the sources and licenses of bundled or adapted components.

## The interesting decision

The harness separates generators from evaluators and retrieves compact project memory instead of loading full transcripts; this reduces self-certification and context growth at the cost of additional orchestration and configuration.

## Run it

```bash
git clone https://github.com/hihihhi/claude-setup.git
cd claude-setup
claude
```

Then run:

```text
/setup
```

For a non-interactive fallback:

```bash
./install.sh
```

```powershell
.\install.ps1
```

Check an installed environment with:

```bash
./scripts/health-check.sh
```

## Status

Active. Installation, source attribution, and a local health-check script are present; an independent end-to-end quality benchmark is not recorded.
