#!/bin/bash
# setup_sdk.sh - Download and setup Fuchsia SDK
# This replaces the full source checkout to avoid rate limiting
# Supports both Linux and macOS

set -e

echo "=== Fuchsia SDK Setup ==="

PROJECT_ROOT=$(pwd)
SDK_DIR="$PROJECT_ROOT/sdk"

# Detect OS and architecture
OS=$(uname -s)
ARCH=$(uname -m)

# Map architecture to SDK naming conventions
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    SDK_ARCH="mac-arm64"
elif [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Darwin" ]; then
        SDK_ARCH="mac-amd64"
    else
        SDK_ARCH="linux-amd64"
    fi
else
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
fi

# Allow SDK version to be pinned via environment variable
SDK_VERSION="${FUCHSIA_SDK_VERSION:-latest}"

# Verify required tools before downloading
if ! command -v curl &> /dev/null; then
    echo "Error: curl not found. Please install curl."
    exit 1
fi

if ! command -v unzip &> /dev/null; then
    echo "Error: unzip not found. Please install unzip."
    exit 1
fi

# 1. Download SDK if not exists
if [ -d "$SDK_DIR/tools" ]; then
    echo "[*] SDK already exists at $SDK_DIR"
else
    echo "[*] Downloading Fuchsia SDK (${SDK_ARCH}) version ${SDK_VERSION}..."
    mkdir -p "$SDK_DIR"
    
    # The SDK is distributed as a CIPD package
    SDK_URL="https://chrome-infra-packages.appspot.com/dl/fuchsia/sdk/core/${SDK_ARCH}/+/${SDK_VERSION}"
    
    echo "[*] Fetching from: $SDK_URL"
    if ! curl -L "$SDK_URL" -o "$SDK_DIR/sdk-package"; then
        echo "Error: Failed to download SDK. Check your internet connection and the SDK version."
        rm -rf "$SDK_DIR"
        exit 1
    fi
    
    echo "[*] Extracting SDK..."
    # The package is a zip file, not tar.gz
    cd "$SDK_DIR"
    if ! unzip -q sdk-package; then
        echo "Error: Failed to extract SDK. The downloaded package may be corrupted."
        rm sdk-package
        cd "$PROJECT_ROOT"
        exit 1
    fi
    rm sdk-package
    cd "$PROJECT_ROOT"
fi

# 2. Create GN configuration
echo "[*] Creating GN configuration..."
cat > "$PROJECT_ROOT/.gn" << 'EOF'
buildconfig = "//build/BUILDCONFIG.gn"

# Use SDK's build templates
import("//sdk/build/config/BUILDCONFIG.gn")
EOF

# 3. Create build directory
mkdir -p "$PROJECT_ROOT/build"

cat > "$PROJECT_ROOT/build/BUILDCONFIG.gn" << 'EOF'
# Soliloquy Build Configuration

if (target_os == "") {
  target_os = "fuchsia"
}

if (target_cpu == "") {
  target_cpu = "arm64"
}

is_debug = true

# Toolchain
set_default_toolchain("//sdk/build/toolchain:fuchsia_arm64")
EOF

# 4. Output environment setup instructions
echo "[*] SDK setup complete!"
echo ""
echo "To use the SDK, set these environment variables:"
echo "  export FUCHSIA_DIR=\"$SDK_DIR\""
if [ "$OS" = "Darwin" ]; then
    echo "  export CLANG_HOST_ARCH=mac-x64"
else
    echo "  export CLANG_HOST_ARCH=linux-x64"
fi
echo "  export PATH=\"\$FUCHSIA_DIR/tools:\$PATH\""
echo ""
echo "You can add these to your shell profile or run them directly in your terminal."
echo "Then run: ./tools/soliloquy/build_sdk.sh to build"
