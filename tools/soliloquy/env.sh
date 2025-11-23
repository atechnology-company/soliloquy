#!/bin/bash
# env.sh - Set up Soliloquy development environment
# Source this file in your shell: source tools/soliloquy/env.sh

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# Determine if we're using SDK or full source
if [ -d "$PROJECT_ROOT/sdk" ]; then
    SDK_DIR="$PROJECT_ROOT/sdk"
    export FUCHSIA_DIR="$SDK_DIR"
elif [ -d "$PROJECT_ROOT/fuchsia/fuchsia" ]; then
    export FUCHSIA_DIR="$PROJECT_ROOT/fuchsia/fuchsia"
else
    echo "Error: Neither SDK ($PROJECT_ROOT/sdk) nor Fuchsia source ($PROJECT_ROOT/fuchsia/fuchsia) found."
    echo "Run './tools/soliloquy/setup_sdk.sh' to download the SDK or './tools/soliloquy/setup.sh' for full source."
    return 1 2>/dev/null || exit 1
fi

# Detect host OS and set CLANG_HOST_ARCH
OS=$(uname -s)
if [ "$OS" = "Darwin" ]; then
    export CLANG_HOST_ARCH=mac-x64
else
    export CLANG_HOST_ARCH=linux-x64
fi

# Add SDK tools to PATH
export PATH="$FUCHSIA_DIR/tools:$PATH"

echo "Soliloquy environment set up:"
echo "  FUCHSIA_DIR=$FUCHSIA_DIR"
echo "  CLANG_HOST_ARCH=$CLANG_HOST_ARCH"
echo "  PATH includes $FUCHSIA_DIR/tools"
