#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Git Clean & Switch Tool
# Safely resets current branch to a remote source, cleans the worktree,
# and prepares a development branch.
# -----------------------------------------------------------------------------

# Default values
REMOTE="origin"
BASE_BRANCH="main"
TARGET_BRANCH="dev"
BACKUP_PREFIX="backup"
BACKUP_BRANCH=""
DRY_RUN=false

usage() {
  cat <<EOF
Git Clean & Switch Tool

Usage: $(basename "$0") [options]

Carefully resets the current branch to a remote source, cleans the worktree,
and prepares a development branch.

Options:
  -b, --base BRANCH     Source branch to reset to (default: main)
  -t, --target BRANCH   Target branch to checkout after reset (default: dev)
  -B, --backup BRANCH   Specific backup branch name (default: backup-<BASE_BRANCH>-<TIMESTAMP>)
  -r, --remote REMOTE   Remote name (default: origin)
  --dry-run             Simulate actions without making changes
  -h, --help            Show this help

Example:
  $(basename "$0") -b main -t feature-work
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--base)    BASE_BRANCH="$2"; shift 2 ;;
        -t|--target)  TARGET_BRANCH="$2"; shift 2 ;;
        -B|--backup)  BACKUP_BRANCH="$2"; shift 2 ;;
        -r|--remote)  REMOTE="$2"; shift 2 ;;
        --dry-run)    DRY_RUN=true; shift ;;
        -h|--help)    usage; exit 0 ;;
        -*)           echo "Unknown option: $1"; usage; exit 1 ;;
        *)            shift ;;
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
    BACKUP_BRANCH="${BACKUP_PREFIX}-${BASE_BRANCH}-${TIMESTAMP}"
fi

# -----------------------------
# Dry-run checks
# -----------------------------
if [[ "$DRY_RUN" == true ]]; then
    echo "🚨 [DRY-RUN] Simulating actions..."
    echo "Remote: $REMOTE"
    echo "Base branch: $BASE_BRANCH"
    echo "Target branch: $TARGET_BRANCH"
    echo "Backup branch: $BACKUP_BRANCH"
    echo "🚨 [DRY-RUN] ... no changes were made."
    exit 0
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
echo "🔄 Resetting current branch to $REMOTE/$BASE_BRANCH..."
git reset --hard "$REMOTE/$BASE_BRANCH" || {
    echo "❌ Failed to reset to $REMOTE/$BASE_BRANCH."
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
