#!/bin/bash
# Copyright 2024 Soliloquy Authors
# SPDX-License-Identifier: Apache-2.0
#
# Download prebuilt Fuchsia QEMU images for testing
# These can be used to test the QEMU setup before building Soliloquy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CACHE_DIR="${PROJECT_ROOT}/.cache/fuchsia-qemu"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}=== Fuchsia QEMU Image Downloader ===${NC}"
echo ""

mkdir -p "${CACHE_DIR}"
cd "${CACHE_DIR}"

# Fuchsia release info
FUCHSIA_VERSION="26.20250117.3.1"
BASE_URL="https://storage.googleapis.com/fuchsia-artifacts/builds"
BUILD_ID="8724597660276891793"  # From Fuchsia CI

echo -e "${CYAN}Downloading Fuchsia ${FUCHSIA_VERSION} QEMU images...${NC}"

# Download kernel (multiboot.bin - bootable kernel)
if [ ! -f "multiboot.bin" ]; then
    echo "Downloading kernel..."
    curl -L -o multiboot.bin.tmp \
        "https://storage.googleapis.com/fuchsia-artifacts/builds/${BUILD_ID}/images/qemu-arm64/multiboot.bin" \
        2>/dev/null || {
        echo -e "${YELLOW}Direct download failed, trying alternative...${NC}"
        # Alternative: Use GCS browser
        echo -e "${YELLOW}Please download manually from:${NC}"
        echo "https://ci.chromium.org/p/fuchsia/builders/global.ci/core.arm64-asan-qemu_kvm/b${BUILD_ID}"
        exit 1
    }
    mv multiboot.bin.tmp multiboot.bin
fi

# Download ZBI
if [ ! -f "fuchsia.zbi" ]; then
    echo "Downloading ZBI..."
    curl -L -o fuchsia.zbi.tmp \
        "https://storage.googleapis.com/fuchsia-artifacts/builds/${BUILD_ID}/images/qemu-arm64/fuchsia.zbi" \
        2>/dev/null || {
        echo -e "${YELLOW}Direct download failed${NC}"
    }
    [ -f fuchsia.zbi.tmp ] && mv fuchsia.zbi.tmp fuchsia.zbi
fi

# Check what we have
echo ""
echo -e "${GREEN}Downloaded files:${NC}"
ls -la "${CACHE_DIR}"/*.zbi "${CACHE_DIR}"/multiboot.bin 2>/dev/null || echo "No files downloaded"

# If we don't have images, provide alternative instructions
if [ ! -f "fuchsia.zbi" ] && [ ! -f "multiboot.bin" ]; then
    echo ""
    echo -e "${YELLOW}Could not download prebuilt images.${NC}"
    echo ""
    echo "Alternative options:"
    echo ""
    echo "1. Build from Fuchsia source (requires Linux):"
    echo "   orb -m fedora"
    echo "   curl -s 'https://fuchsia.googlesource.com/fuchsia/+/HEAD/scripts/bootstrap?format=TEXT' | base64 --decode | bash"
    echo "   cd ~/fuchsia"
    echo "   fx set core.qemu-arm64"
    echo "   fx build"
    echo "   fx qemu"
    echo ""
    echo "2. Use Fuchsia Emulator (FEMU) from SDK:"
    echo "   Visit: https://fuchsia.dev/fuchsia-src/get-started/sdk"
    echo ""
    exit 1
fi

echo ""
echo -e "${GREEN}Images ready!${NC}"
echo ""
echo "To run:"
echo "  ./tools/soliloquy/run_qemu.sh -k ${CACHE_DIR}/fuchsia.zbi"
