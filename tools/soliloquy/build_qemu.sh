#!/bin/bash
# Copyright 2024 Soliloquy Authors
# SPDX-License-Identifier: Apache-2.0
#
# Build Soliloquy for QEMU ARM64
#
# This script builds a ZBI (Zircon Boot Image) suitable for QEMU testing.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== Building Soliloquy for QEMU ARM64 ==="
echo ""

# Create output directory
mkdir -p "${WORKSPACE_ROOT}/out"

# Build with Bazel
echo "Building with Bazel..."
cd "${WORKSPACE_ROOT}"

# Build the shell and drivers
bazel build \
    //src/shell:soliloquy_shell_simple \
    //drivers/generic:soliloquy_drivers \
    //boards/arm64/qemu:qemu_board_config \
    2>&1 | tail -20

echo ""
echo "=== Build Complete ==="
echo ""
echo "Built artifacts:"
ls -la bazel-bin/src/shell/ 2>/dev/null | grep -E '\.(a|rlib|bin)$' || true
ls -la bazel-bin/drivers/generic/ 2>/dev/null | grep -E '\.(a|rlib)$' || true
echo ""

# Check if we have a full Fuchsia build available
if [ -f "${WORKSPACE_ROOT}/out/default/soliloquy.zbi" ]; then
    echo "Full ZBI found: out/default/soliloquy.zbi"
    cp "${WORKSPACE_ROOT}/out/default/soliloquy.zbi" "${WORKSPACE_ROOT}/out/soliloquy.zbi"
    echo "Copied to: out/soliloquy.zbi"
elif [ -f "/Volumes/storage/fuchsia-src/out/default/qemu-arm64.zbi" ]; then
    echo "Found Fuchsia ZBI, copying..."
    cp "/Volumes/storage/fuchsia-src/out/default/qemu-arm64.zbi" "${WORKSPACE_ROOT}/out/soliloquy.zbi"
    echo "Copied to: out/soliloquy.zbi"
else
    echo "Note: No complete ZBI available yet."
    echo ""
    echo "To build a bootable ZBI, you need the full Fuchsia build:"
    echo ""
    echo "  # One-time setup (requires Linux or Linux VM)"
    echo "  ./tools/soliloquy/setup.sh"
    echo ""
    echo "  # Build with fx"
    echo "  ./tools/soliloquy/build.sh"
    echo ""
    echo "For now, you can test individual components with:"
    echo "  bazel test //src/shell:soliloquy_shell_tests"
    echo "  bazel test //drivers/generic:soliloquy_drivers_test"
fi

echo ""
echo "To run in QEMU (once ZBI is built):"
echo "  ./tools/soliloquy/run_qemu.sh"
echo ""
echo "QEMU options:"
echo "  -g    Enable graphics (virtio-gpu)"
echo "  -n    Enable network (port forwards: SSH=2222, HTTP=8080)"
echo "  -d    Enable GDB debug server on port 1234"
