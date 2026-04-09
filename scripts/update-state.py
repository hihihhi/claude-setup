#!/usr/bin/env python3
"""Stop hook. Auto-updates .claude/state.md in the current project.

Reads current state.md if it exists, updates the "Last Updated" timestamp,
appends session summary info from environment if available, and creates
state.md with a template if it doesn't exist.
"""

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

STATE_TEMPLATE = """\
# Project State

## Last Updated
{timestamp}

## Current Task State
- Phase: idle
- Status: no active task

## Session Intermediate Results
<!-- Findings from the current session: URLs, decisions, outputs -->

## Long-term Notes
<!-- Persistent notes. Preferences go to ~/.claude/projects/*/memory/ -->

## Recent Sessions
| Date | Summary |
|------|---------|
| {date} | Session initialized |
"""


def find_project_root() -> Path | None:
    """Walk up from cwd to find .claude/ directory or .git root."""
    cwd = Path.cwd()

    # First check if .claude exists in cwd
    if (cwd / ".claude").is_dir():
        return cwd

    # Walk up looking for .git or .claude
    for parent in [cwd] + list(cwd.parents):
        if (parent / ".claude").is_dir():
            return parent
        if (parent / ".git").exists():
            return parent

    # Default to cwd
    return cwd


def get_timestamp() -> str:
    """Return ISO 8601 timestamp in local time."""
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def get_date() -> str:
    """Return date string."""
    return datetime.now().strftime("%Y-%m-%d")


def update_timestamp(content: str) -> str:
    """Update the Last Updated timestamp in state.md content."""
    timestamp = get_timestamp()
    # Match "## Last Updated" followed by a date/time on the next line
    pattern = r"(## Last Updated\n).*"
    replacement = rf"\g<1>{timestamp}"
    updated = re.sub(pattern, replacement, content)
    if updated == content and "## Last Updated" not in content:
        # Section doesn't exist, add it after the title
        lines = content.split("\n")
        insert_idx = 1 if len(lines) > 0 else 0
        lines.insert(insert_idx, f"\n## Last Updated\n{timestamp}\n")
        updated = "\n".join(lines)
    return updated


def append_session_summary(content: str) -> str:
    """Append session info from environment variables if available."""
    summary = os.environ.get("CLAUDE_SESSION_SUMMARY", "")
    task = os.environ.get("CLAUDE_CURRENT_TASK", "")

    if not summary and not task:
        return content

    date = get_date()
    entry = summary or task or "Session ended"

    # Truncate long summaries
    if len(entry) > 120:
        entry = entry[:117] + "..."

    # Append to Recent Sessions table
    session_row = f"| {date} | {entry} |"

    if "## Recent Sessions" in content:
        # Find the table and append a row
        lines = content.split("\n")
        insert_idx = None
        in_table = False
        for i, line in enumerate(lines):
            if "## Recent Sessions" in line:
                in_table = True
                continue
            if in_table and line.startswith("##"):
                insert_idx = i
                break
            if in_table and line.startswith("|") and "---" not in line:
                insert_idx = i + 1

        if insert_idx is not None:
            lines.insert(insert_idx, session_row)
            content = "\n".join(lines)
    else:
        content += f"\n## Recent Sessions\n| Date | Summary |\n|------|---------|"
        content += f"\n{session_row}\n"

    return content


def main() -> None:
    project_root = find_project_root()
    if project_root is None:
        return

    claude_dir = project_root / ".claude"
    state_file = claude_dir / "state.md"

    # Create .claude directory if needed
    claude_dir.mkdir(parents=True, exist_ok=True)

    if state_file.exists():
        try:
            content = state_file.read_text(encoding="utf-8")
        except OSError:
            return

        content = update_timestamp(content)
        content = append_session_summary(content)

        try:
            state_file.write_text(content, encoding="utf-8")
        except OSError:
            pass
    else:
        # Create from template
        timestamp = get_timestamp()
        date = get_date()
        content = STATE_TEMPLATE.format(timestamp=timestamp, date=date)

        try:
            state_file.write_text(content, encoding="utf-8")
        except OSError:
            pass


if __name__ == "__main__":
    main()
