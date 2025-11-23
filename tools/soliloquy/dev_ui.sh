#!/bin/bash
# dev_ui.sh - Development helper for Soliloquy Tauri Shell UI
# This script provides a convenient way to run the Tauri development server

set -e

echo "=== Soliloquy Shell UI Development ==="

PROJECT_ROOT=$(pwd)
UI_DIR="$PROJECT_ROOT/ui/tauri-shell"

if [ ! -d "$UI_DIR" ]; then
    echo "Error: Tauri UI directory not found at $UI_DIR"
    echo "Please ensure you're running this from the project root"
    exit 1
fi

cd "$UI_DIR"

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "[*] Installing dependencies..."
    npm install
fi

# Check if Rust/Tauri dependencies are available
if ! command -v cargo &> /dev/null; then
    echo "Error: Rust/Cargo not found."
    echo "Please install Rust first:"
    echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    echo "  source ~/.cargo/env"
    echo ""
    echo "After installing Rust, run this script again."
    exit 1
fi

if ! command -v tauri &> /dev/null; then
    echo "[*] Installing Tauri CLI..."
    cargo install tauri-cli
fi

# Check if we're on macOS and provide additional setup
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "[*] Detected macOS - checking for additional dependencies..."
    
    # Check for Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        echo "Error: Xcode Command Line Tools not found."
        echo "Please run: xcode-select --install"
        exit 1
    fi
    
    # Check for system dependencies
    if ! command -v brew &> /dev/null; then
        echo "Warning: Homebrew not found. Some dependencies may be missing."
    else
        echo "[*] Checking for system dependencies via Homebrew..."
        brew list openssl &> /dev/null || echo "Consider installing: brew install openssl"
        brew list pkg-config &> /dev/null || echo "Consider installing: brew install pkg-config"
    fi
fi

echo "[*] Starting development server..."
echo "The Soliloquy Shell UI will open in a new window."
echo "Press Ctrl+C to stop the development server."
echo ""

# Try to run Tauri development server first
if command -v tauri &> /dev/null && command -v cargo &> /dev/null; then
    echo "Starting Tauri development server..."
    npm run tauri:dev
else
    echo "Tauri not available. Starting Svelte development server only..."
    echo "Note: This will run the UI in a browser window instead of a desktop app."
    echo "Install Rust and Tauri CLI for the full desktop experience."
    echo ""
    npm run dev
fi