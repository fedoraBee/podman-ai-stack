#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# GitOps PR CLI Tool
# Release-aware + RPM + CI integration
# -----------------------------

if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    exit 1
fi

# -----------------------------
# Usage
# -----------------------------
usage() {
  cat <<EOF
GitOps PR CLI Tool v2 (Release-aware)

Usage:
  $(basename "$0") -b BASE -h BRANCH [-t TITLE] [-m BODY] [-r REVIEWERS]

Required:
  -b Base branch (e.g. main)
  -h Head branch (feat/vX.Y.Z-description)

Optional:
  -t PR title (default: auto-generated from commits)
  -m PR body (default: auto-generated)
  -r Reviewers (comma-separated)

Example:
  $(basename "$0") -b main -h feat/v0.2.0-login-fix
EOF
}

BASE_BRANCH=""
HEAD_BRANCH=""
PR_TITLE=""
PR_BODY=""
REVIEWERS=""

# -----------------------------
# Parse args
# -----------------------------
while getopts "b:h:t:m:r:" opt; do
    case "$opt" in
        b) BASE_BRANCH="$OPTARG" ;;
        h) HEAD_BRANCH="$OPTARG" ;;
        t) PR_TITLE="$OPTARG" ;;
        m) PR_BODY="$OPTARG" ;;
        r) REVIEWERS="$OPTARG" ;;
        *) usage; exit 1 ;;
    esac
done

# -----------------------------
# Validation
# -----------------------------
if [[ -z "$BASE_BRANCH" || -z "$HEAD_BRANCH" ]]; then
    echo "Error: Missing required arguments."
    usage
    exit 1
fi

# Branch naming enforcement (Gemini.md)
if [[ ! "$HEAD_BRANCH" =~ ^(feat|fix|chore|refactor|docs|ci)/v[0-9]+\.[0-9]+\.[0-9]+- ]]; then
    echo "❌ Invalid branch name: $HEAD_BRANCH"
    echo "Expected: <type>/v<version>-<description>"
    exit 1
fi

# Extract version
if [[ "$HEAD_BRANCH" =~ v([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    VERSION="${BASH_REMATCH[1]}"
else
    echo "❌ Could not extract version from branch"
    exit 1
fi

echo "📦 Detected version: v$VERSION"

# -----------------------------
# Git safety checks
# -----------------------------
echo "Fetching base branch..."
git fetch origin "$BASE_BRANCH"

# Ensure repo is clean
if [[ -n "$(git status --porcelain)" ]]; then
    echo "❌ Working tree is not clean. Commit or stash changes first."
    exit 1
fi

# -----------------------------
# Create / switch branch
# -----------------------------
if git show-ref --verify --quiet "refs/heads/$HEAD_BRANCH"; then
    echo "🔀 Switching to existing branch: $HEAD_BRANCH"
    git switch "$HEAD_BRANCH"
else
    echo "🌱 Creating branch: $HEAD_BRANCH"
    git switch -c "$HEAD_BRANCH"
fi

# -----------------------------
# Sync with base (rebase safety)
# -----------------------------
echo "🔄 Rebasing on origin/$BASE_BRANCH..."
git rebase "origin/$BASE_BRANCH" || {
    echo "❌ Rebase failed. Resolve conflicts manually."
    exit 1
}

# -----------------------------
# Validate CHANGELOG
# -----------------------------
if [[ ! -f "CHANGELOG.md" ]]; then
    echo "❌ CHANGELOG.md missing"
    exit 1
fi

if ! grep -q "$VERSION" CHANGELOG.md; then
    echo "❌ CHANGELOG.md does not contain version v$VERSION"
    exit 1
fi

echo "✅ CHANGELOG contains version"

# -----------------------------
# Validate RPM spec version
# -----------------------------
SPEC_FILE=$(find rpm -name "*.spec" | head -n 1 || true)

if [[ -z "$SPEC_FILE" ]]; then
    echo "❌ RPM spec file not found"
    exit 1
fi

if ! grep -q "$VERSION" "$SPEC_FILE"; then
    echo "❌ RPM spec does not contain version v$VERSION"
    exit 1
fi

echo "✅ RPM spec version matches"

# -----------------------------
# Commit analysis for PR body
# -----------------------------
if [[ -z "$PR_TITLE" ]]; then
    PR_TITLE=$(git log --pretty=format:"%s" origin/"$BASE_BRANCH"..HEAD | head -n 1)
fi

if [[ -z "$PR_BODY" ]]; then
    echo "📝 Generating PR body from commits..."
    PR_BODY=$(git log --pretty=format:"- %s" origin/"$BASE_BRANCH"..HEAD)
fi

PR_BODY_FULL="## Version
v$VERSION

## Changes
$PR_BODY"

# -----------------------------
# Push branch
# -----------------------------
echo "🚀 Pushing branch..."
git push -u origin "$HEAD_BRANCH"

# -----------------------------
# Create PR
# -----------------------------
CMD=(gh pr create
    --base "$BASE_BRANCH"
    --head "$HEAD_BRANCH"
    --title "$PR_TITLE"
    --body "$PR_BODY_FULL"
)

if [[ -n "$REVIEWERS" ]]; then
    CMD+=(--reviewer "$REVIEWERS")
fi

echo "📬 Creating Pull Request..."
"${CMD[@]}"

echo "✅ GitOps PR created successfully (v$VERSION)"