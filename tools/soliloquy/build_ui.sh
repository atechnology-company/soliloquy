#!/bin/bash
# build_ui.sh - Build the Soliloquy UI (web-only version for now)

set -e

echo "=== Soliloquy Shell UI Build ==="

PROJECT_ROOT=$(pwd)
UI_DIR="$PROJECT_ROOT/ui/tauri-shell"

if [ ! -d "$UI_DIR" ]; then
    echo "Error: Tauri UI directory not found at $UI_DIR"
    exit 1
fi

cd "$UI_DIR"

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "[*] Installing dependencies..."
    npm install
fi

echo "[*] Building UI for production..."

# Build the SvelteKit application
npm run build

if [ $? -eq 0 ]; then
    echo "[*] Build successful!"
    echo "Output is in: build/"
    echo ""
    echo "To serve the built files:"
    echo "  npx serve build -p 3000"
    echo ""
    echo "Note: This is the web-only version. For the full desktop app,"
    echo "install Rust and run: npm run tauri:build"
else
    echo "[*] Build failed!"
    exit 1
fi