#!/usr/bin/env python3
"""Dynamic memory injection hook for Claude Code (UserPromptSubmit).

Reads the user's prompt from stdin (JSON), searches ~/.claude/projects/*/memory/*.md
for keyword matches using TF-IDF-like scoring, and prints the top 3 most relevant
memory file contents to stdout for context injection.
"""

import json
import math
import os
import re
import sys
from collections import Counter
from pathlib import Path

# Words too common to be useful signals
STOP_WORDS = frozenset({
    "a", "an", "the", "is", "it", "in", "on", "at", "to", "for", "of", "and",
    "or", "not", "with", "this", "that", "from", "by", "as", "be", "was", "are",
    "were", "been", "has", "have", "had", "do", "does", "did", "will", "would",
    "could", "should", "may", "might", "can", "i", "me", "my", "we", "you",
    "your", "he", "she", "they", "them", "its", "but", "if", "so", "no", "yes",
    "just", "also", "how", "what", "when", "where", "why", "who", "which",
    "all", "each", "every", "any", "some", "about", "up", "out", "than", "then",
    "very", "more", "most", "other", "into", "over", "only", "use", "using",
})

MAX_RESULTS = 3
MAX_CONTENT_LINES = 60


def tokenize(text: str) -> list[str]:
    """Extract lowercase alphanumeric tokens, filtering stop words."""
    tokens = re.findall(r"[a-z0-9_\-]+", text.lower())
    return [t for t in tokens if t not in STOP_WORDS and len(t) > 1]


def get_memory_dir() -> Path:
    """Resolve ~/.claude/projects/ cross-platform."""
    return Path.home() / ".claude" / "projects"


def find_memory_files() -> list[Path]:
    """Glob all memory markdown files across all projects."""
    base = get_memory_dir()
    if not base.exists():
        return []
    return list(base.glob("*/memory/*.md"))


def compute_idf(doc_token_lists: list[list[str]]) -> dict[str, float]:
    """Compute inverse document frequency for each token across all docs."""
    n_docs = len(doc_token_lists)
    if n_docs == 0:
        return {}
    doc_freq: Counter = Counter()
    for tokens in doc_token_lists:
        doc_freq.update(set(tokens))
    return {
        token: math.log((n_docs + 1) / (freq + 1)) + 1
        for token, freq in doc_freq.items()
    }


def score_document(
    query_tokens: list[str],
    doc_tokens: list[str],
    idf: dict[str, float],
) -> float:
    """Score a document against query tokens using TF-IDF cosine-like metric."""
    if not doc_tokens or not query_tokens:
        return 0.0
    doc_tf = Counter(doc_tokens)
    doc_len = len(doc_tokens)
    score = 0.0
    for qt in set(query_tokens):
        tf = doc_tf.get(qt, 0) / doc_len
        weight = idf.get(qt, 1.0)
        score += tf * weight
    return score


def read_file_safe(path: Path, max_lines: int = MAX_CONTENT_LINES) -> str:
    """Read a file, returning at most max_lines. Handles encoding errors."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            lines = []
            for i, line in enumerate(f):
                if i >= max_lines:
                    lines.append(f"\n... (truncated at {max_lines} lines)")
                    break
                lines.append(line)
            return "".join(lines)
    except OSError:
        return ""


def find_memory_index() -> str:
    """Fallback: read MEMORY.md index if it exists."""
    candidates = [
        Path.home() / ".claude" / "MEMORY.md",
        Path.home() / ".claude" / "memory" / "MEMORY.md",
    ]
    for p in candidates:
        if p.exists():
            return read_file_safe(p)
    return ""


def main() -> None:
    # Read hook input from stdin
    try:
        raw = sys.stdin.read()
        data = json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        return

    # Extract the user's prompt
    prompt = ""
    if isinstance(data, dict):
        prompt = data.get("prompt", "") or data.get("tool_input", "")
        if isinstance(prompt, dict):
            prompt = prompt.get("prompt", "") or prompt.get("user_message", "")
    if not prompt or not isinstance(prompt, str):
        return

    query_tokens = tokenize(prompt)
    if not query_tokens:
        return

    # Find and score memory files
    memory_files = find_memory_files()
    if not memory_files:
        fallback = find_memory_index()
        if fallback:
            print(f"<!-- Memory Index -->\n{fallback}")
        return

    # Read and tokenize all documents
    doc_data: list[tuple[Path, str, list[str]]] = []
    for path in memory_files:
        content = read_file_safe(path)
        if content.strip():
            tokens = tokenize(content)
            doc_data.append((path, content, tokens))

    if not doc_data:
        return

    # Compute IDF across corpus
    idf = compute_idf([tokens for _, _, tokens in doc_data])

    # Score each document
    scored: list[tuple[float, Path, str]] = []
    for path, content, tokens in doc_data:
        score = score_document(query_tokens, tokens, idf)
        if score > 0:
            scored.append((score, path, content))

    scored.sort(key=lambda x: x[0], reverse=True)

    if not scored:
        fallback = find_memory_index()
        if fallback:
            print(f"<!-- Memory Index -->\n{fallback}")
        return

    # Output top results
    results = scored[:MAX_RESULTS]
    parts = []
    for score, path, content in results:
        rel = path.name
        project = path.parent.parent.name if path.parent.name == "memory" else "unknown"
        parts.append(
            f"<!-- Memory: {project}/{rel} (relevance: {score:.3f}) -->\n{content}"
        )

    print("\n---\n".join(parts))


if __name__ == "__main__":
    main()
