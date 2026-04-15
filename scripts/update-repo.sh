#!/bin/bash
# Script to update the DNF repository metadata with versioned channels
#
# This script organizes RPMs into a versioned structure (e.g., v0.1/stable)
# and maintains a 'latest' pointer for each channel.

set -e

# --- Configuration ---
RPM_SOURCE_DIR=${1:-"rpmbuild/RPMS/noarch"}
VERSION=${2:-"0.1.0"}
CHANNEL=${3:-"stable"}
GPG_KEY_ID=${4}
REPO_ROOT="rpmbuild/repo"

# --- Functions ---
usage() {
    echo "Usage: $0 [rpm_source_dir] [version] [channel] [gpg_key_id]"
    echo "Example: $0 rpmbuild/RPMS/noarch 0.1.0 stable 9B99A03F6577BF59"
}

check_dependencies() {
    local deps=("createrepo_c" "gpg" "rpm")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            echo "Error: Required command '$dep' not found. Please install it."
            exit 1
        fi
    done
}

# --- Execution ---
check_dependencies

# Attempt to discover GPG_KEY_ID from RPM macros if not provided as argument
if [ -z "$GPG_KEY_ID" ]; then
    GPG_KEY_ID=$(rpm --eval '%{?_gpg_name}' 2>/dev/null || true)
fi

# Calculate versioned directory name (vMAJOR.MINOR)
MAJOR_MINOR=$(echo "$VERSION" | cut -d. -f1,2)
VERSION_DIR="$REPO_ROOT/v$MAJOR_MINOR/$CHANNEL"
LATEST_DIR="$REPO_ROOT/latest/$CHANNEL"

echo "Updating DNF repository..."
echo "  Source RPMs: $RPM_SOURCE_DIR"
echo "  Version:     $VERSION (v$MAJOR_MINOR)"
echo "  Channel:     $CHANNEL"
[ -n "$GPG_KEY_ID" ] && echo "  Signing Key: $GPG_KEY_ID" || echo "  Signing Key: [NONE]"

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

# Sign repository metadata if a GPG key is available
if [ -n "$GPG_KEY_ID" ]; then
    echo "Signing metadata in $VERSION_DIR with GPG key: $GPG_KEY_ID"
    # --batch --yes for non-interactive signing; --local-user to specify the key
    # Use --armor for easier web transport
    rm -f "$VERSION_DIR/repodata/repomd.xml.asc" # Ensure fresh signature
    gpg --detach-sign --armor --batch --yes --pinentry-mode loopback --local-user "$GPG_KEY_ID" "$VERSION_DIR/repodata/repomd.xml"
else
    echo "Warning: No GPG key available. Repository metadata will not be signed."
fi

# Sync the versioned channel to the 'latest' pointer
echo "Syncing $VERSION_DIR to $LATEST_DIR..."
if command -v rsync >/dev/null 2>&1; then
    rsync -av --delete "$VERSION_DIR/" "$LATEST_DIR/"
else
    # Fallback to rm/cp if rsync is not available
    rm -rf "${LATEST_DIR:?}"/*
    cp -r "$VERSION_DIR/"* "$LATEST_DIR/"
fi

# Copy GPG public key if it exists in the root directory
if [ -f "gpg.key" ]; then
    echo "Copying gpg.key to repo root..."
    cp "gpg.key" "$REPO_ROOT/"
fi

echo "Repository update complete in $REPO_ROOT"
