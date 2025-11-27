#!/usr/bin/env bash
# Test display detection on Zircon target device
#
# Usage: ./scripts/zircon/display_detect.sh
#
# This script runs on a Fuchsia/Zircon device to test display detection
# via the Zircon scenic service.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Ensure we're on Fuchsia
assert_fuchsia

echo "=== Soliloquy Display Detection (Zircon) ==="
echo ""

# Check display devices
echo "Display Devices:"
if [[ -d "/dev/class/display" ]]; then
    display_count=0
    for device in /dev/class/display/*; do
        if [[ -e "$device" ]]; then
            device_name=$(basename "$device")
            echo "  ✓ /dev/class/display/$device_name"
            ((display_count++))
        fi
    done
    
    if [[ $display_count -eq 0 ]]; then
        echo "  ⚠ No display devices found"
    fi
else
    echo "  ✗ /dev/class/display/ does not exist"
fi

echo ""

# Check scenic services
echo "Scenic Services:"
services=(
    "fuchsia.ui.display.singleton.Info"
    "fuchsia.ui.composition.Flatland"
    "fuchsia.ui.composition.Allocator"
    "fuchsia.ui.scenic.Scenic"
    "fuchsia.ui.input3.Keyboard"
)

for service in "${services[@]}"; do
    if [[ -e "/svc/$service" ]]; then
        echo "  ✓ $service"
    else
        echo "  ✗ $service (not available)"
    fi
done

echo ""

# Determine mode
echo "Mode Determination:"
if [[ -d "/dev/class/display" ]] && [[ -n "$(ls -A /dev/class/display 2>/dev/null)" ]]; then
    echo "  📺 Display detected - DESKTOP MODE"
    echo ""
    echo "  Soliloquy will:"
    echo "    - Start Servo browser engine"
    echo "    - Initialize V8 JavaScript runtime"
    echo "    - Render Svelte UI via Flatland compositor"
    echo "    - Enable Cupboard local storage + sync"
else
    echo "  📡 No display - HEADLESS MODE"
    echo ""
    echo "  Soliloquy will:"
    echo "    - Run as Cupboard sync server"
    echo "    - Expose REST API at http://localhost:3030"
    echo "    - Accept sync from other devices"
    echo "    - Skip Servo/V8 initialization"
fi

echo ""
echo "=== Test Complete ==="
