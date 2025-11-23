#!/bin/bash
# build_sdk.sh - Build Soliloquy using Fuchsia SDK

set -e

PROJECT_ROOT=$(pwd)
SDK_DIR="$PROJECT_ROOT/sdk"

if [ ! -d "$SDK_DIR/tools" ]; then
    echo "Error: SDK not found. Run ./tools/soliloquy/setup_sdk.sh first"
    exit 1
fi

export PATH="$SDK_DIR/tools:$PATH"

echo "=== Soliloquy SDK Build ==="

# Generate build files
echo "[*] Generating build files..."
gn gen out/arm64 --args='target_cpu="arm64" target_os="fuchsia" is_debug=true'

# Build
echo "[*] Building..."
ninja -C out/arm64

echo "=== Build Complete ==="
echo "Output: out/arm64/"
