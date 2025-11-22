#!/bin/bash
# flash.sh - Flash Soliloquy OS to SD Card

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <device_path>"
    echo "Example: $0 /dev/sdX"
    exit 1
fi

DEVICE=$1
IMAGE_PATH="$HOME/fuchsia/out/minimal.arm64/fuchsia.zbi" # Adjust path based on build output

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    echo "Run ./build.sh first."
    exit 1
fi

echo "WARNING: This will overwrite all data on $DEVICE"
read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo "=== Flashing Image ==="
# This is a placeholder. Actual flashing command depends on the specific image format and bootloader requirements for Allwinner A527
# Typically involves dd or a specific flashing tool.
echo "Writing $IMAGE_PATH to $DEVICE..."
sudo dd if="$IMAGE_PATH" of="$DEVICE" bs=4M status=progress conv=fsync

echo "=== Flash Complete ==="
