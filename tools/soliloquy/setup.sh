#!/bin/bash
# setup.sh - Soliloquy OS Environment Setup
# Target: Linux (Debian/Ubuntu based)

set -e

echo "=== Soliloquy OS Setup ==="

# 1. Install Prerequisites
echo "[*] Installing dependencies..."
sudo apt-get update
sudo apt-get install -y git curl unzip python3 python3-pip build-essential gcc g++ make

# 2. Clone Fuchsia (if not exists)
FUCHSIA_DIR="$HOME/fuchsia"
if [ -d "$FUCHSIA_DIR" ]; then
    echo "[*] Fuchsia directory exists at $FUCHSIA_DIR"
else
    echo "[*] Cloning Fuchsia repository..."
    git clone https://fuchsia.googlesource.com/fuchsia "$FUCHSIA_DIR"
fi

# 3. Bootstrap Fuchsia
echo "[*] Bootstrapping Fuchsia..."
cd "$FUCHSIA_DIR"
scripts/bootstrap

# 4. Setup Environment
echo "[*] Setting up environment..."
source scripts/fx-env.sh

echo "=== Setup Complete ==="
echo "Please run: source $FUCHSIA_DIR/scripts/fx-env.sh"
