#!/bin/bash
# Soliloquy OS Build Setup for OrbStack Fedora
# Run this script inside the Fedora orb

set -e

echo "========================================="
echo "Soliloquy OS Build Environment Setup"
echo "========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
FUCHSIA_DIR="${FUCHSIA_DIR:-/mnt/mac/Volumes/storage/fuchsia-src}"
SOLILOQUY_DIR="${SOLILOQUY_DIR:-/mnt/mac/Volumes/storage/GitHub/soliloquy}"

echo -e "${YELLOW}Fuchsia source directory: $FUCHSIA_DIR${NC}"
echo -e "${YELLOW}Soliloquy directory: $SOLILOQUY_DIR${NC}"
echo ""

# Step 1: Install dependencies
echo -e "${GREEN}[1/6] Installing build dependencies...${NC}"
sudo dnf install -y \
    git curl wget \
    python3 python3-pip \
    unzip zip \
    ccache \
    clang lld llvm \
    ninja-build \
    go \
    flex bison gperf \
    texinfo \
    openssl-devel \
    dtc \
    u-boot-tools \
    libstdc++-static \
    gcc-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu \
    --skip-unavailable || true

# Step 2: Install Bazelisk
echo -e "${GREEN}[2/6] Installing Bazelisk...${NC}"
if ! command -v bazel &> /dev/null; then
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ]; then
        BAZEL_ARCH="arm64"
    else
        BAZEL_ARCH="amd64"
    fi
    curl -L -o /tmp/bazelisk \
        "https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-linux-$BAZEL_ARCH"
    chmod +x /tmp/bazelisk
    sudo mv /tmp/bazelisk /usr/local/bin/bazel
fi
echo "Bazel version: $(bazel --version)"

# Step 3: Bootstrap jiri
echo -e "${GREEN}[3/6] Setting up Fuchsia jiri...${NC}"
mkdir -p "$FUCHSIA_DIR"
cd "$FUCHSIA_DIR"

if [ ! -f "$FUCHSIA_DIR/.jiri_root/bin/jiri" ]; then
    curl -s 'https://fuchsia.googlesource.com/jiri/+/HEAD/scripts/bootstrap_jiri?format=TEXT' \
        | base64 --decode | bash -s "$FUCHSIA_DIR"
fi

export PATH="$FUCHSIA_DIR/.jiri_root/bin:$PATH"

# Initialize jiri if needed
if [ ! -f "$FUCHSIA_DIR/.jiri_manifest" ]; then
    jiri init -analytics-opt=false "$FUCHSIA_DIR"
    jiri import -name=integration flower https://fuchsia.googlesource.com/integration
fi

# Step 4: Add to bashrc
echo -e "${GREEN}[4/6] Configuring shell...${NC}"
BASHRC_ENTRY="export PATH=\"$FUCHSIA_DIR/.jiri_root/bin:\$PATH\""
if ! grep -q "jiri_root" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Fuchsia/Soliloquy build environment" >> ~/.bashrc
    echo "$BASHRC_ENTRY" >> ~/.bashrc
    echo "export FUCHSIA_DIR=\"$FUCHSIA_DIR\"" >> ~/.bashrc
    echo "export SOLILOQUY_DIR=\"$SOLILOQUY_DIR\"" >> ~/.bashrc
fi

# Step 5: Link Soliloquy into Fuchsia tree
echo -e "${GREEN}[5/6] Linking Soliloquy components...${NC}"
mkdir -p "$FUCHSIA_DIR/vendor/soliloquy"
ln -sf "$SOLILOQUY_DIR/src/shell" "$FUCHSIA_DIR/vendor/soliloquy/shell" 2>/dev/null || true
ln -sf "$SOLILOQUY_DIR/drivers" "$FUCHSIA_DIR/vendor/soliloquy/drivers" 2>/dev/null || true
ln -sf "$SOLILOQUY_DIR/product" "$FUCHSIA_DIR/vendor/soliloquy/product" 2>/dev/null || true
ln -sf "$SOLILOQUY_DIR/boards" "$FUCHSIA_DIR/vendor/soliloquy/boards" 2>/dev/null || true

# Step 6: Check status
echo -e "${GREEN}[6/6] Checking setup status...${NC}"
echo ""
echo "========================================="
echo -e "${GREEN}Setup complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo ""
echo -e "${YELLOW}1. Fetch Fuchsia source (takes 1-2 hours):${NC}"
echo "   cd $FUCHSIA_DIR"
echo "   jiri update -gc"
echo ""
echo -e "${YELLOW}2. Configure build:${NC}"
echo "   source scripts/fx-env.sh"
echo "   fx set core.arm64 --with //vendor/soliloquy/shell"
echo ""
echo -e "${YELLOW}3. Build:${NC}"
echo "   fx build"
echo ""
echo -e "${YELLOW}4. Test with QEMU:${NC}"
echo "   fx set core.qemu-arm64 --with //vendor/soliloquy/shell"
echo "   fx build && fx qemu"
echo ""
echo "For Bazel-only build (no full Fuchsia):"
echo "   cd $SOLILOQUY_DIR"
echo "   bazel build //..."
echo ""

# Check if jiri update is needed
if [ ! -d "$FUCHSIA_DIR/zircon" ]; then
    echo -e "${RED}WARNING: Fuchsia source not yet downloaded.${NC}"
    echo "Run 'jiri update -gc' to fetch (~60GB, 1-2 hours)"
fi
