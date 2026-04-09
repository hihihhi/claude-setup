#!/usr/bin/env python3
"""PreToolUse hook for Bash commands. Blocks dangerous commands.

Reads tool input from stdin as JSON, checks the command against a blocklist
of dangerous patterns using regex, and returns a JSON verdict.
"""

import json
import re
import sys
from typing import Optional

# Each rule: (compiled regex, severity, reason)
# severity: "block" = hard stop, "warn" = allow but warn
RULES: list[tuple[re.Pattern, str, str]] = [
    # Destructive filesystem operations
    (
        re.compile(r"rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+)?(-[a-zA-Z]*r[a-zA-Z]*\s+)?\s*/\s*$"
                    r"|rm\s+(-[a-zA-Z]*r[a-zA-Z]*\s+)?(-[a-zA-Z]*f[a-zA-Z]*\s+)?\s*/\s*$"
                    r"|rm\s+-rf\s+/\s*$"
                    r"|rm\s+-rf\s+/[^a-zA-Z]"),
        "block",
        "Recursive delete of root filesystem",
    ),
    (
        re.compile(r"rm\s+(-[a-zA-Z]*r[a-zA-Z]*\s+)(-[a-zA-Z]*f[a-zA-Z]*)?\s*~"
                    r"|rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+)(-[a-zA-Z]*r[a-zA-Z]*)?\s*~"
                    r"|rm\s+-rf\s+~"
                    r"|rm\s+-rf\s+\$HOME"
                    r"|rm\s+-rf\s+\$\{HOME\}"),
        "block",
        "Recursive delete of home directory",
    ),
    # Force push to main/master
    (
        re.compile(
            r"git\s+push\s+.*--force.*\s+(main|master)"
            r"|git\s+push\s+.*-f\s+.*\s+(main|master)"
            r"|git\s+push\s+--force.*\s+origin\s+(main|master)"
            r"|git\s+push\s+-f\s+origin\s+(main|master)",
            re.IGNORECASE,
        ),
        "block",
        "Force push to main/master branch",
    ),
    # git reset --hard (warn, don't block)
    (
        re.compile(r"git\s+reset\s+--hard"),
        "warn",
        "git reset --hard will discard all uncommitted changes",
    ),
    # sudo rm / sudo dd
    (
        re.compile(r"sudo\s+rm\s"),
        "block",
        "sudo rm is extremely dangerous",
    ),
    (
        re.compile(r"sudo\s+dd\s"),
        "block",
        "sudo dd can overwrite disk devices",
    ),
    # Pipe to shell (curl/wget piped to sh/bash)
    (
        re.compile(
            r"curl\s+.*\|\s*(ba)?sh"
            r"|wget\s+.*\|\s*(ba)?sh"
            r"|curl\s+.*\|\s*sudo\s+(ba)?sh"
            r"|wget\s+.*\|\s*sudo\s+(ba)?sh",
        ),
        "block",
        "Piping remote content to shell is unsafe",
    ),
    # SQL destruction
    (
        re.compile(r"DROP\s+(TABLE|DATABASE)", re.IGNORECASE),
        "block",
        "DROP TABLE/DATABASE detected",
    ),
    # Insecure permissions
    (
        re.compile(r"chmod\s+777"),
        "block",
        "chmod 777 sets world-writable permissions",
    ),
    # Fork bomb
    (
        re.compile(r":\(\)\s*\{\s*:\|:\s*&\s*\}\s*;\s*:"),
        "block",
        "Fork bomb detected",
    ),
    # Additional fork bomb variants
    (
        re.compile(r"\.\(\)\s*\{\s*\.\s*\|\s*\.\s*&\s*\}"),
        "block",
        "Fork bomb variant detected",
    ),
]


def check_command(command: str) -> tuple[str, Optional[str]]:
    """Check a command against all rules. Returns (decision, reason)."""
    for pattern, severity, reason in RULES:
        if pattern.search(command):
            if severity == "block":
                return "block", reason
            # For warnings, we still allow but include the reason
            return "allow", f"WARNING: {reason}"
    return "allow", None


def make_response(decision: str, reason: str = "") -> str:
    """Build Claude Code hook response JSON."""
    perm = "deny" if decision == "block" else "allow"
    output: dict = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": perm,
        }
    }
    if reason:
        output["hookSpecificOutput"]["permissionDecisionReason"] = reason
    return json.dumps(output)


def main() -> None:
    try:
        raw = sys.stdin.read()
        data = json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        return

    # Extract the command from tool input
    command = ""
    if isinstance(data, dict):
        tool_input = data.get("tool_input", data)
        if isinstance(tool_input, dict):
            command = tool_input.get("command", "")
        elif isinstance(tool_input, str):
            command = tool_input

    if not command:
        return

    decision, reason = check_command(command)

    if decision == "block":
        print(make_response("block", reason or "Blocked by bash-guard"))
    elif reason:
        # Warn but allow — inject reason as context
        resp = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "additionalContext": reason,
            }
        }
        print(json.dumps(resp))


if __name__ == "__main__":
    main()
