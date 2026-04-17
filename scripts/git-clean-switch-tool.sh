#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Git Clean & Switch Tool
# Safely resets current branch to a remote source, cleans the worktree,
# and prepares a development branch.
# -----------------------------------------------------------------------------

# Default values
REMOTE="origin"
SOURCE_BRANCH="main"
TARGET_BRANCH="dev"
BACKUP_PREFIX="backup"
BACKUP_BRANCH=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Carefully resets the current branch to a remote source, cleans the worktree,
and prepares a development branch.

Options:
  -s, --source BRANCH   Source branch to reset to (default: main)
  -t, --target BRANCH   Target branch to checkout after reset (default: dev)
  -b, --backup BRANCH   Specific backup branch name (default: backup-<SOURCE_BRANCH>-<TIMESTAMP>)
  -r, --remote REMOTE   Remote name (default: origin)
  -h, --help            Show this help

Example:
  $(basename "$0") -s main -t feature-work
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source) SOURCE_BRANCH="$2"; shift 2 ;;
        -t|--target) TARGET_BRANCH="$2"; shift 2 ;;
        -b|--backup) BACKUP_BRANCH="$2"; shift 2 ;;
        -r|--remote) REMOTE="$2"; shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        -*)          echo "Unknown option: $1"; usage; exit 1 ;;
        *)           shift ;;
    esac
done

# Ensure we are in a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "❌ Error: Not a git repository."
    exit 1
fi

# Set default backup branch if not provided
if [[ -z "$BACKUP_BRANCH" ]]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_BRANCH="${BACKUP_PREFIX}-${SOURCE_BRANCH}-${TIMESTAMP}"
fi

echo "🔍 Starting git sync and reset sequence..."

# 1. Create backup of current state
echo "📦 Creating backup branch: $BACKUP_BRANCH"
git branch -f "$BACKUP_BRANCH"

# 2. Fetch latest from remote
echo "📡 Fetching from $REMOTE..."
git fetch "$REMOTE" || {
    echo "❌ Failed to fetch from $REMOTE."
    exit 1
}

# 3. Reset to remote source
echo "🔄 Resetting current branch to $REMOTE/$SOURCE_BRANCH..."
git reset --hard "$REMOTE/$SOURCE_BRANCH" || {
    echo "❌ Failed to reset to $REMOTE/$SOURCE_BRANCH."
    exit 1
}

# 4. Clean untracked files
echo "🧹 Cleaning untracked files and directories..."
git clean -fd

# 5. Switch to target branch
echo "🌱 Switching to target branch: $TARGET_BRANCH"
git checkout -B "$TARGET_BRANCH" || {
    echo "❌ Failed to checkout $TARGET_BRANCH."
    exit 1
}

echo "✅ Git reset and dev setup complete."
echo "   - Current branch: $TARGET_BRANCH"
echo "   - Backup created: $BACKUP_BRANCH"
