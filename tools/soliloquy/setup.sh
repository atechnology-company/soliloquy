#!/bin/bash
# setup.sh - Soliloquy OS Environment Setup
# Target: Linux (Debian/Ubuntu based)

set -e

echo "=== Soliloquy OS Setup ==="

# 1. Install Prerequisites
echo "[*] Installing dependencies..."
if command -v dnf &> /dev/null; then
    echo "Detected Fedora/RHEL..."
    sudo dnf install -y git curl unzip python3 python3-pip @development-tools gcc-c++ make
elif command -v apt-get &> /dev/null; then
    echo "Detected Debian/Ubuntu..."
    sudo apt-get update
    sudo apt-get install -y git curl unzip python3 python3-pip build-essential gcc g++ make
else
    echo "Error: Unsupported package manager. Please install dependencies manually."
    exit 1
fi

# 2. Clone Fuchsia (if not exists)
# Use a directory relative to the script execution (project root)
PROJECT_ROOT=$(pwd)
# Note: Due to previous clone behavior, the checkout is nested in fuchsia/fuchsia
FUCHSIA_DIR="$PROJECT_ROOT/fuchsia/fuchsia"

if [ -d "$FUCHSIA_DIR" ]; then
    echo "[*] Fuchsia directory exists at $FUCHSIA_DIR"
else
    echo "[*] Cloning Fuchsia repository to $FUCHSIA_DIR..."
    git clone https://fuchsia.googlesource.com/fuchsia "$FUCHSIA_DIR"
fi

# 3. Bootstrap Fuchsia
echo "[*] Bootstrapping Fuchsia..."
cd "$FUCHSIA_DIR"
if ! scripts/bootstrap; then
    echo "[!] Bootstrap failed. This is often due to Google Source rate limiting (HTTP 429)."
    echo "[*] Waiting 30 seconds before retrying with reduced parallelism..."
    sleep 30
    
    if [ -f ".jiri_root/bin/jiri" ]; then
        echo "[*] Retrying 'jiri update' with -j 1 (sequential download)..."
        .jiri_root/bin/jiri update -j 1
    else
        echo "[X] Critical: jiri binary not found. Cannot recover."
        exit 1
    fi
fi
cd "$PROJECT_ROOT"

# 4. Clone Servo (if not exists)
SERVO_DIR="$PROJECT_ROOT/vendor/servo"
if [ -d "$SERVO_DIR/.git" ]; then
    echo "[*] Servo directory exists at $SERVO_DIR"
else
    echo "[*] Cloning Servo repository..."
    # Create parent dir if needed
    mkdir -p "$(dirname "$SERVO_DIR")"
    git clone https://github.com/servo/servo.git "$SERVO_DIR"
fi

# 5. Link Soliloquy Sources into Fuchsia Tree
echo "[*] Linking Soliloquy sources..."
# Create vendor directory
mkdir -p "$FUCHSIA_DIR/vendor/soliloquy"

# Link Board
mkdir -p "$FUCHSIA_DIR/boards/arm64"
ln -sfn "$PROJECT_ROOT/boards/arm64/soliloquy" "$FUCHSIA_DIR/boards/arm64/soliloquy"

# Link Drivers
# We'll place drivers in vendor/soliloquy/drivers for now
mkdir -p "$FUCHSIA_DIR/vendor/soliloquy/drivers"
ln -sfn "$PROJECT_ROOT/drivers/wifi/aic8800" "$FUCHSIA_DIR/vendor/soliloquy/drivers/aic8800"

# Link Shell
mkdir -p "$FUCHSIA_DIR/vendor/soliloquy/src"
ln -sfn "$PROJECT_ROOT/src/shell" "$FUCHSIA_DIR/vendor/soliloquy/src/shell"

# Link Servo
ln -sfn "$SERVO_DIR" "$FUCHSIA_DIR/vendor/servo"

# 6. Setup Environment
echo "[*] Setting up environment..."
source scripts/fx-env.sh

echo "=== Setup Complete ==="
echo "Please run: source $FUCHSIA_DIR/scripts/fx-env.sh"
