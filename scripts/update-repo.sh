#!/bin/bash
# Script to update the DNF repository metadata

set -e

REPO_DIR=${1:-"rpmbuild/RPMS/noarch/"}
GPG_KEY_ID=${2}

if [ ! -d "$REPO_DIR" ]; then
    echo "Creating repository directory: $REPO_DIR"
    mkdir -p "$REPO_DIR"
fi

echo "Updating repository metadata in $REPO_DIR..."
createrepo_c --update "$REPO_DIR"

if [ -n "$GPG_KEY_ID" ]; then
    echo "Signing repository metadata with GPG key: $GPG_KEY_ID"
    gpg --detach-sign --armor "$REPO_DIR/repodata/repomd.xml"
fi

echo "Repository update complete."
