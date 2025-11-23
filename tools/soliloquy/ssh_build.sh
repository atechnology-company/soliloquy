#!/bin/bash
# ssh_build.sh - Run Soliloquy build on remote host
# Usage: ./tools/soliloquy/ssh_build.sh [remote_host]

REMOTE_HOST=${1:-"undivisible@fedora@orb"}
# Use the mounted path directly. OrbStack typically mounts /Volumes at /Volumes or /mnt/mac/Volumes.
# We'll try the direct path first as it's most common on macOS hosts.
REMOTE_DIR="/Volumes/storage/GitHub/soliloquy"

echo "=== Soliloquy Remote Build ($REMOTE_HOST) ==="
echo "Target Directory: $REMOTE_DIR"

# 1. No Sync Needed (Building in-place on mounted drive)
echo "[*] Building directly on mounted drive (Skipping rsync)..."

# 2. Run Build
echo "[*] Triggering build..."
ssh -t "$REMOTE_HOST" "cd \"$REMOTE_DIR\" && ./tools/soliloquy/setup.sh && ./tools/soliloquy/build.sh"

# 3. Artifacts are already local (in ./out)
echo "=== Build Complete ==="
