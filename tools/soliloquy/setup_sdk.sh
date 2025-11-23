#!/bin/bash
# setup_sdk.sh - Download and setup Fuchsia SDK
# This replaces the full source checkout to avoid rate limiting

set -e

echo "=== Fuchsia SDK Setup ==="

PROJECT_ROOT=$(pwd)
SDK_DIR="$PROJECT_ROOT/sdk"

# 1. Download SDK if not exists
if [ -d "$SDK_DIR/tools" ]; then
    echo "[*] SDK already exists at $SDK_DIR"
else
    echo "[*] Downloading Fuchsia SDK..."
    mkdir -p "$SDK_DIR"
    
    # The SDK is distributed as a CIPD package, not a simple tarball
    # We need to download the SDK archive directly
    SDK_VERSION="latest"
    
    # Use the direct download URL for the SDK tarball
    curl -L "https://chrome-infra-packages.appspot.com/dl/fuchsia/sdk/core/linux-amd64/+/$SDK_VERSION" -o "$SDK_DIR/sdk-package"
    
    echo "[*] Extracting SDK..."
    # The package is a zip file, not tar.gz
    cd "$SDK_DIR"
    unzip -q sdk-package
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

# 4. Update PATH
echo "[*] SDK setup complete!"
echo "Add to your PATH: export PATH=\"$SDK_DIR/tools:\$PATH\""
echo "Run: ./tools/soliloquy/build_sdk.sh to build"
