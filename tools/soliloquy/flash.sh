#!/bin/bash
# flash.sh - Flash Soliloquy to SD Card

set -e

PROJECT_ROOT=$(pwd)
# Default to the Soliloquy product image
# To build: fx set core.arm64 --with //product:soliloquy && fx build
DEFAULT_PRODUCT_IMAGE="$PROJECT_ROOT/fuchsia/fuchsia/out/default/obj/build/images/soliloquy/soliloquy.zbi"
DEFAULT_LEGACY_IMAGE="$PROJECT_ROOT/fuchsia/fuchsia/out/default/fuchsia.zbi"

IMAGE_PATH="${1:-$DEFAULT_PRODUCT_IMAGE}"

# Fall back to legacy image if product image doesn't exist
if [ ! -f "$IMAGE_PATH" ] && [ -f "$DEFAULT_LEGACY_IMAGE" ]; then
    echo "Note: Using legacy image path. Consider building with //product:soliloquy"
    IMAGE_PATH="$DEFAULT_LEGACY_IMAGE"
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    echo ""
    echo "To build the Soliloquy product image:"
    echo "  1. Set up the build: fx set core.arm64 --with //product:soliloquy"
    echo "  2. Build the product: fx build"
    echo "  3. Flash: ./tools/soliloquy/flash.sh"
    echo ""
    echo "Or specify a custom image path:"
    echo "  ./tools/soliloquy/flash.sh /path/to/custom.zbi"
    exit 1
fi

echo "=== Flashing Soliloquy ==="
echo "Image: $IMAGE_PATH"
echo "Waiting for device in fastboot mode..."

fastboot wait-for-device

echo "[*] Flashing Zircon Boot Image (ZBI)..."
# Note: Partition name 'boot' is standard, but might vary for A527 (e.g., 'boot_a', 'boot_b')
fastboot flash boot "$IMAGE_PATH"

echo "[*] Rebooting..."
fastboot reboot

echo "=== Flashing Complete ==="
