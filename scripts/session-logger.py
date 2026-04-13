#!/usr/bin/env python3
"""
session-logger.py — Stop hook
Logs session outcome to ~/.claude/sessions/YYYYMMDD-HHMMSS.md
and indexes it in ~/.claude/sessions/sessions.db (SQLite + FTS5).

Inspired by: NousResearch/hermes-agent session DB + FTS5 lineage pattern.
Hook config (settings.json):
  "Stop": [{"id": "session-logger", "command": "python3 ~/.claude/scripts/session-logger.py", "timeout": 5000}]
"""
import json
import sys
import os
import pathlib
import sqlite3
import datetime

# ── Read hook input ────────────────────────────────────────────────────────────
try:
    data = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)  # never crash on bad input — exit 0 to let Claude continue

session_id  = data.get("session_id", "unknown")
cwd         = data.get("cwd", os.getcwd())
messages    = data.get("messages", [])
stop_reason = data.get("stop_reason", "")

# ── Paths ──────────────────────────────────────────────────────────────────────
claude_home  = pathlib.Path.home() / ".claude"
sessions_dir = claude_home / "sessions"
sessions_dir.mkdir(parents=True, exist_ok=True)
db_path      = sessions_dir / "sessions.db"

# ── Build session summary ──────────────────────────────────────────────────────
now = datetime.datetime.now()
timestamp = now.strftime("%Y%m%d-%H%M%S")

# Extract text from messages (assistant turns only)
assistant_text = []
user_text = []
tools_used = set()

for msg in messages:
    role = msg.get("role", "")
    content = msg.get("content", "")
    if isinstance(content, str):
        if role == "assistant":
            assistant_text.append(content[:500])
        elif role == "user":
            user_text.append(content[:200])
    elif isinstance(content, list):
        for block in content:
            if isinstance(block, dict):
                if block.get("type") == "text":
                    text = block.get("text", "")
                    if role == "assistant":
                        assistant_text.append(text[:500])
                    elif role == "user":
                        user_text.append(text[:200])
                elif block.get("type") == "tool_use":
                    tools_used.add(block.get("name", ""))
                elif block.get("type") == "tool_result":
                    pass

# First user message = task description
task_desc = user_text[0] if user_text else "unknown task"
# Last assistant message = final output summary
final_output = assistant_text[-1] if assistant_text else ""

# ── Write session log file ─────────────────────────────────────────────────────
log_file = sessions_dir / f"{timestamp}.md"
log_content = f"""---
session_id: {session_id}
timestamp: {now.isoformat()}
cwd: {cwd}
stop_reason: {stop_reason}
tools_used: {', '.join(sorted(tools_used)) or 'none'}
---

## Task
{task_desc[:1000]}

## Summary
{final_output[:2000]}
"""

try:
    log_file.write_text(log_content, encoding="utf-8")
except Exception:
    sys.exit(0)

# ── Index in SQLite FTS5 ───────────────────────────────────────────────────────
try:
    con = sqlite3.connect(db_path)
    cur = con.cursor()

    # Create tables if first run
    cur.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT,
            timestamp TEXT,
            cwd TEXT,
            task_desc TEXT,
            tools_used TEXT,
            log_path TEXT
        )
    """)
    cur.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS sessions_fts USING fts5(
            session_id,
            task_desc,
            tools_used,
            content='sessions',
            content_rowid='id'
        )
    """)

    cur.execute("""
        INSERT INTO sessions (session_id, timestamp, cwd, task_desc, tools_used, log_path)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (session_id, now.isoformat(), cwd, task_desc[:2000],
          ','.join(sorted(tools_used)), str(log_file)))

    row_id = cur.lastrowid
    cur.execute("""
        INSERT INTO sessions_fts (rowid, session_id, task_desc, tools_used)
        VALUES (?, ?, ?, ?)
    """, (row_id, session_id, task_desc[:2000], ','.join(sorted(tools_used))))

    # Prune old sessions (keep last 200)
    cur.execute("""
        DELETE FROM sessions WHERE id NOT IN (
            SELECT id FROM sessions ORDER BY id DESC LIMIT 200
        )
    """)

    con.commit()
    con.close()
except Exception:
    pass  # DB failure is non-fatal

sys.exit(0)
