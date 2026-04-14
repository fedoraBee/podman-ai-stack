#!/bin/bash
# Script to update the DNF repository metadata with versioned channels

set -e

# Configuration
RPM_SOURCE_DIR=${1:-"rpmbuild/RPMS/noarch"}
VERSION=${2:-"0.1.0"}
CHANNEL=${3:-"stable"}
GPG_KEY_ID=${4}
REPO_ROOT="rpmbuild/repo"

# Calculate versioned directory name (vMAJOR.MINOR)
MAJOR_MINOR=$(echo "$VERSION" | cut -d. -f1,2)
VERSION_DIR="$REPO_ROOT/v$MAJOR_MINOR/$CHANNEL"
LATEST_DIR="$REPO_ROOT/latest/$CHANNEL"

echo "Updating DNF repository..."
echo "  Source RPMs: $RPM_SOURCE_DIR"
echo "  Version:     $VERSION (v$MAJOR_MINOR)"
echo "  Channel:     $CHANNEL"

# Ensure directories exist
mkdir -p "$VERSION_DIR"
mkdir -p "$LATEST_DIR"

# Copy RPMs from build directory to the versioned repository directory
if [ -d "$RPM_SOURCE_DIR" ] && [ "$(ls -A "$RPM_SOURCE_DIR"/*.rpm 2>/dev/null)" ]; then
    echo "Copying RPMs to $VERSION_DIR..."
    cp "$RPM_SOURCE_DIR"/*.rpm "$VERSION_DIR/"
else
    echo "Error: No RPMs found in $RPM_SOURCE_DIR"
    exit 1
fi

# Update repository metadata for the versioned channel
echo "Updating metadata in $VERSION_DIR..."
createrepo_c --update "$VERSION_DIR"

# Sign repository metadata if GPG key is provided
if [ -n "$GPG_KEY_ID" ]; then
    echo "Signing metadata in $VERSION_DIR with GPG key: $GPG_KEY_ID"
    # Use --batch --yes for non-interactive signing in CI/CD
    gpg --detach-sign --armor --batch --yes --local-user "$GPG_KEY_ID" "$VERSION_DIR/repodata/repomd.xml"
fi

# Sync the versioned channel to the 'latest' pointer
echo "Syncing $VERSION_DIR to $LATEST_DIR..."
if command -v rsync >/dev/null 2>&1; then
    rsync -av --delete "$VERSION_DIR/" "$LATEST_DIR/"
else
    # Fallback to rm/cp if rsync is not available
    rm -rf "$LATEST_DIR"/*
    cp -r "$VERSION_DIR/"* "$LATEST_DIR/"
fi

echo "Repository update complete in $REPO_ROOT"
