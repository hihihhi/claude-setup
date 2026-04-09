#!/usr/bin/env python3
"""PreToolUse hook for Write/Edit tools. Detects hardcoded secrets.

Reads tool input from stdin as JSON, scans file content for secret patterns,
and blocks the operation if potential secrets are found.
"""

import json
import os
import re
import sys
from typing import Optional

# File extensions to skip (docs may discuss patterns, tests use fakes)
SKIP_EXTENSIONS = frozenset({".md", ".mdx", ".rst", ".txt"})

# Patterns that indicate a test/example value (case-insensitive)
FAKE_VALUE_PATTERNS = re.compile(
    r"(test|example|fake|dummy|placeholder|xxx|your[-_]?|replace[-_]?me"
    r"|sample|mock|TODO|CHANGEME|INSERT[-_]?HERE)",
    re.IGNORECASE,
)

# Secret detection rules: (name, pattern, extract_group)
SECRET_PATTERNS: list[tuple[str, re.Pattern, Optional[int]]] = [
    # API key prefixes
    ("OpenAI API key (sk-)", re.compile(r"sk-[a-zA-Z0-9]{20,}"), None),
    ("Stripe key (pk_/sk_)", re.compile(
        r"(?:pk|sk)_(?:live|test)_[a-zA-Z0-9]{20,}"
    ), None),
    ("AWS Access Key ID", re.compile(r"AKIA[0-9A-Z]{16}"), None),
    ("GitHub token (ghp_)", re.compile(r"ghp_[a-zA-Z0-9]{36,}"), None),
    ("GitHub OAuth token (gho_)", re.compile(r"gho_[a-zA-Z0-9]{36,}"), None),
    ("GitLab token (glpat-)", re.compile(r"glpat-[a-zA-Z0-9\-_]{20,}"), None),
    ("Slack bot token (xoxb-)", re.compile(r"xoxb-[a-zA-Z0-9\-]+"), None),
    ("Slack user token (xoxp-)", re.compile(r"xoxp-[a-zA-Z0-9\-]+"), None),

    # AWS Secret Access Key (40 char base64-ish after a key indicator)
    ("AWS Secret Access Key", re.compile(
        r"(?:aws_secret_access_key|secret_key|secretAccessKey)"
        r"\s*[=:]\s*['\"]?"
        r"([a-zA-Z0-9/+=]{40})"
        r"['\"]?",
        re.IGNORECASE,
    ), 1),

    # Private keys
    ("Private key", re.compile(
        r"-----BEGIN\s+(?:RSA|EC|OPENSSH|DSA|PGP)?\s*PRIVATE\s+KEY-----"
    ), None),

    # Generic secret assignments (password/secret/token = "value")
    ("Hardcoded password", re.compile(
        r"""(?<!#\s)(?<!//\s)(?<!<!--\s)"""
        r"""(?:password|passwd|pwd)\s*[=:]\s*['"][^'"]{4,}['"]""",
        re.IGNORECASE,
    ), None),
    ("Hardcoded secret", re.compile(
        r"""(?<!#\s)(?<!//\s)(?<!<!--\s)"""
        r"""(?:secret|secret_key|api_secret)\s*[=:]\s*['"][^'"]{4,}['"]""",
        re.IGNORECASE,
    ), None),
    ("Hardcoded token", re.compile(
        r"""(?<!#\s)(?<!//\s)(?<!<!--\s)"""
        r"""(?:token|api_token|auth_token|access_token)\s*[=:]\s*['"][^'"]{8,}['"]""",
        re.IGNORECASE,
    ), None),
    ("Hardcoded API key", re.compile(
        r"""(?<!#\s)(?<!//\s)(?<!<!--\s)"""
        r"""(?:api_key|apikey|api-key)\s*[=:]\s*['"][^'"]{8,}['"]""",
        re.IGNORECASE,
    ), None),

    # Connection strings with passwords
    ("Connection string with password", re.compile(
        r"(?:mysql|postgres|postgresql|mongodb|redis|amqp|mssql)"
        r"://[^:]+:[^@]+@[^/\s]+",
        re.IGNORECASE,
    ), None),
]


def is_test_file(file_path: str) -> bool:
    """Check if the file is a test file."""
    basename = os.path.basename(file_path).lower()
    test_indicators = (
        "test_", "_test.", ".test.", "spec_", "_spec.", ".spec.",
        "test.", "mock_", "_mock.", "fixture", "fake_",
    )
    test_dirs = ("/test/", "/tests/", "/__tests__/", "/spec/", "/fixtures/")
    return (
        any(basename.startswith(t) or t in basename for t in test_indicators)
        or any(d in file_path.replace("\\", "/") for d in test_dirs)
    )


def is_fake_value(match_text: str) -> bool:
    """Check if the matched value looks like a placeholder/test value."""
    return bool(FAKE_VALUE_PATTERNS.search(match_text))


def scan_content(content: str, file_path: str) -> list[str]:
    """Scan content for secret patterns. Returns list of findings."""
    # Skip documentation files
    _, ext = os.path.splitext(file_path)
    if ext.lower() in SKIP_EXTENSIONS:
        return []

    is_test = is_test_file(file_path)
    findings: list[str] = []

    for name, pattern, group in SECRET_PATTERNS:
        for match in pattern.finditer(content):
            matched_text = match.group(group) if group else match.group(0)

            # Skip obvious fakes in test files
            if is_test and is_fake_value(matched_text):
                continue

            # Skip env var references (not actual secrets)
            if matched_text.startswith("$") or matched_text.startswith("%"):
                continue

            # Skip if value is an env var lookup
            env_patterns = [
                "os.environ", "os.getenv", "process.env",
                "env(", "ENV[", "getenv(",
            ]
            # Check surrounding context (20 chars before match)
            start = max(0, match.start() - 40)
            context = content[start:match.end()]
            if any(ep in context for ep in env_patterns):
                continue

            # For generic patterns, skip if the "value" looks fake
            if is_fake_value(matched_text):
                continue

            # Truncate for display
            display = matched_text[:30] + "..." if len(matched_text) > 30 else matched_text
            line_num = content[:match.start()].count("\n") + 1
            findings.append(f"{name} at line {line_num}: {display}")

    return findings


def main() -> None:
    try:
        raw = sys.stdin.read()
        data = json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        return

    if not isinstance(data, dict):
        return

    tool_input = data.get("tool_input", data)
    if not isinstance(tool_input, dict):
        return

    # Extract file path and content based on tool type
    file_path = tool_input.get("file_path", "")

    # For Write tool: content field; for Edit tool: new_string field
    content = tool_input.get("content", "") or tool_input.get("new_string", "")

    if not content or not file_path:
        return

    findings = scan_content(content, file_path)

    if findings:
        reason = "Potential secret(s) detected:\n" + "\n".join(
            f"  - {f}" for f in findings
        )
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }))


if __name__ == "__main__":
    main()
