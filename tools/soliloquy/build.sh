#!/bin/bash
# build.sh - Build Soliloquy OS

set -e

FUCHSIA_DIR="$HOME/fuchsia"
if [ -z "$FUCHSIA_DIR" ]; then
    echo "Error: FUCHSIA_DIR not set. Have you sourced fx-env.sh?"
    exit 1
fi

cd "$FUCHSIA_DIR"

echo "=== Configuring Build ==="
# Configure for minimal ARM64 build with Soliloquy board
# Note: We will update this to point to our specific board definition once fully implemented
fx set minimal.arm64 \
  --with-base //src/connectivity/network \
  --with-base //src/graphics/display \
  --args='exclude_starnix=true' \
  --args='exclude_devtools=true'

echo "=== Starting Build ==="
fx build

echo "=== Build Complete ==="
