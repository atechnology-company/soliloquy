#!/bin/bash
# build_bazel.sh - Build Soliloquy using Bazel

set -e

PROJECT_ROOT=$(pwd)
SDK_DIR="$PROJECT_ROOT/sdk"

if [ ! -d "$SDK_DIR" ]; then
    echo "Error: SDK not found. Run ./tools/soliloquy/setup_sdk.sh first"
    exit 1
fi

echo "=== Soliloquy Bazel Build ==="

# Build all targets
echo "[*] Building..."
bazel build //...

echo "=== Build Complete ==="
echo "Output: bazel-bin/"
