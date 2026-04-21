#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${1:-./ai-stack-backups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEST_DIR="$BACKUP_DIR/$TIMESTAMP"

mkdir -p "$DEST_DIR"

echo "📦 Starting Podman AI Stack Backup..."
echo "Backup destination: $DEST_DIR"

# Pause containers to ensure data consistency
echo "⏸️  Pausing containers..."
podman pause open-webui || echo "⚠️ Could not pause open-webui (may not be running)"
podman pause ollama || echo "⚠️ Could not pause ollama (may not be running)"

# Export volumes
echo "💾 Exporting open-webui volume..."
podman volume export open-webui > "$DEST_DIR/open-webui-backup.tar" || echo "❌ Failed to export open-webui volume"

echo "💾 Exporting ollama volume..."
podman volume export ollama > "$DEST_DIR/ollama-backup.tar" || echo "❌ Failed to export ollama volume"

# Unpause containers
echo "▶️  Unpausing containers..."
podman unpause open-webui || true
podman unpause ollama || true

echo "✅ Backup complete: $DEST_DIR"
