#!/bin/bash
# flash.sh - Flash Soliloquy OS to SD Card

set -e

PROJECT_ROOT=$(pwd)
# Note: Build output is in the nested fuchsia directory
IMAGE_PATH="${1:-$PROJECT_ROOT/fuchsia/fuchsia/out/default/fuchsia.zbi}"

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    echo "Run ./tools/soliloquy/ssh_build.sh first."
    exit 1
fi

echo "=== Flashing Soliloquy OS ==="
echo "Image: $IMAGE_PATH"
echo "Waiting for device in fastboot mode..."

fastboot wait-for-device

echo "[*] Flashing Zircon Boot Image (ZBI)..."
# Note: Partition name 'boot' is standard, but might vary for A527 (e.g., 'boot_a', 'boot_b')
fastboot flash boot "$IMAGE_PATH"

echo "[*] Rebooting..."
fastboot reboot

echo "=== Flashing Complete ==="
