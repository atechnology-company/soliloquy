#!/bin/bash
# build.sh - Build Soliloquy OS

set -e

PROJECT_ROOT=$(pwd)
# Note: Due to previous clone behavior, the checkout is nested in fuchsia/fuchsia
FUCHSIA_DIR="$PROJECT_ROOT/fuchsia/fuchsia"

if [ ! -d "$FUCHSIA_DIR" ]; then
    echo "Error: Fuchsia directory not found at $FUCHSIA_DIR"
    exit 1
fi

# Source fx-env.sh to get fx tool
source "$FUCHSIA_DIR/scripts/fx-env.sh"

cd "$FUCHSIA_DIR"

echo "=== Configuring Build ==="
# Configure for minimal ARM64 build with Soliloquy board
# Note: We will update this to point to our specific board definition once fully implemented
fx set minimal.arm64 \
  --with-base //src/connectivity/network \
  --with-base //src/graphics/display \
  --with //vendor/soliloquy/src/shell:soliloquy_shell \
  --with //vendor/soliloquy/drivers/aic8800:aic8800 \
  --args='exclude_starnix=true' \
  --args='exclude_devtools=true'

echo "=== Starting Build ==="
fx build

echo "=== Build Complete ==="
