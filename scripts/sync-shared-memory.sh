#!/usr/bin/env bash
# Syncs shared team knowledge base from a git repo.
#
# Pulls from CLAUDE_SHARED_MEMORY_REPO, syncs to ~/.claude/shared-memory/,
# pushes local changes, and handles merge conflicts gracefully.
#
# Usage:
#   CLAUDE_SHARED_MEMORY_REPO=git@github.com:org/shared-memory.git ./sync-shared-memory.sh
#   Or add to cron: */30 * * * * CLAUDE_SHARED_MEMORY_REPO=... /path/to/sync-shared-memory.sh

set -euo pipefail

SHARED_MEMORY_DIR="${CLAUDE_SHARED_MEMORY_DIR:-$HOME/.claude/shared-memory}"
REPO_URL="${CLAUDE_SHARED_MEMORY_REPO:-}"
BRANCH="${CLAUDE_SHARED_MEMORY_BRANCH:-main}"
LOG_FILE="${CLAUDE_SHARED_MEMORY_LOG:-$HOME/.claude/shared-memory-sync.log}"

log() {
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

die() {
    log "ERROR: $*"
    exit 1
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Validate configuration
if [ -z "$REPO_URL" ]; then
    die "CLAUDE_SHARED_MEMORY_REPO environment variable is not set.
Set it to your team's shared memory git repo URL.
Example: export CLAUDE_SHARED_MEMORY_REPO=git@github.com:org/shared-memory.git"
fi

# Initial clone if directory doesn't exist
if [ ! -d "$SHARED_MEMORY_DIR" ]; then
    log "Cloning shared memory repo from $REPO_URL ..."
    mkdir -p "$(dirname "$SHARED_MEMORY_DIR")"
    if ! git clone "$REPO_URL" "$SHARED_MEMORY_DIR" 2>>"$LOG_FILE"; then
        die "Failed to clone repository: $REPO_URL"
    fi
    log "Clone complete."
    exit 0
fi

# Verify it's a git repo
if [ ! -d "$SHARED_MEMORY_DIR/.git" ]; then
    die "$SHARED_MEMORY_DIR exists but is not a git repository.
Remove it and re-run to clone fresh, or set CLAUDE_SHARED_MEMORY_DIR to a different path."
fi

cd "$SHARED_MEMORY_DIR"

# Ensure we're on the right branch
current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
if [ "$current_branch" != "$BRANCH" ]; then
    log "Switching from '$current_branch' to '$BRANCH'"
    git checkout "$BRANCH" 2>>"$LOG_FILE" || git checkout -b "$BRANCH" 2>>"$LOG_FILE"
fi

# Stage any local changes before pulling
has_local_changes=false
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    has_local_changes=true
    hostname="$(hostname 2>/dev/null || echo "unknown")"
    user="$(whoami 2>/dev/null || echo "unknown")"
    log "Staging local changes ..."
    git add -A
    git commit -m "auto-sync: local changes from ${user}@${hostname} at $(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        2>>"$LOG_FILE" || true
fi

# Pull with rebase to keep history clean
log "Pulling from remote ..."
pull_result=0
git pull --rebase origin "$BRANCH" 2>>"$LOG_FILE" || pull_result=$?

if [ $pull_result -ne 0 ]; then
    # Check if we're in a rebase conflict state
    if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
        log "Merge conflict detected during rebase. Resolving by keeping both versions ..."

        # For each conflicted file, accept the incoming version
        # (team changes take priority; local changes will be re-applied next sync)
        conflicted_files="$(git diff --name-only --diff-filter=U 2>/dev/null || true)"
        if [ -n "$conflicted_files" ]; then
            log "Conflicted files: $conflicted_files"
            # Accept theirs for all conflicts and continue
            echo "$conflicted_files" | while IFS= read -r file; do
                if [ -f "$file" ]; then
                    git checkout --theirs "$file" 2>/dev/null || true
                    git add "$file" 2>/dev/null || true
                fi
            done
            git rebase --continue 2>>"$LOG_FILE" || true
        fi

        # If still in conflict, abort and try merge instead
        if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
            log "Rebase still conflicted. Aborting rebase, trying merge ..."
            git rebase --abort 2>>"$LOG_FILE" || true
            git pull --no-rebase origin "$BRANCH" -X theirs 2>>"$LOG_FILE" || {
                log "Merge also failed. Manual intervention needed."
                log "Directory: $SHARED_MEMORY_DIR"
                exit 1
            }
        fi
    else
        log "Pull failed (not a conflict). Check network connectivity."
        log "Will retry on next sync."
        exit 1
    fi
fi

# Push local changes if we had any
if [ "$has_local_changes" = true ]; then
    log "Pushing local changes ..."
    if ! git push origin "$BRANCH" 2>>"$LOG_FILE"; then
        log "Push failed. Changes are committed locally and will be pushed on next sync."
    else
        log "Push complete."
    fi
fi

log "Sync complete. $(git log --oneline -1 2>/dev/null || echo 'no commits')"
