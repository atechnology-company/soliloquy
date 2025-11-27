#!/bin/bash
# build_ui.sh - Build the Soliloquy Servo desktop UI (static bundle for Servo)

set -euo pipefail

echo "=== Soliloquy Servo Desktop UI Build ==="

PROJECT_ROOT=$(pwd)
UI_DIR="$PROJECT_ROOT/ui/desktop"

if [ ! -d "$UI_DIR" ]; then
    echo "Error: Servo desktop UI directory not found at $UI_DIR"
    exit 1
fi

if ! command -v pnpm &> /dev/null; then
    echo "Error: pnpm not found. Enable it with: corepack enable pnpm"
    exit 1
fi

cd "$UI_DIR"

if [ ! -d "node_modules" ]; then
    echo "[*] Installing dependencies with pnpm (Svelte v5 bundle)..."
    pnpm install
fi

echo "[*] Building static bundle for Servo/V8 runtime..."
pnpm build

echo "[*] Build complete. Artifacts are in: build/"
echo "    Serve with: pnpm dlx serve build -l 4173"
echo "    Or point Servo to ui/desktop/build/index.html"
