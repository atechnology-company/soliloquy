#!/bin/bash
set -e

echo "Installing Soliloquy Build Manager..."

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64)  echo "x86_64" ;;
        arm64)   echo "aarch64" ;;
        aarch64) echo "aarch64" ;;
        *)       echo "unknown" ;;
    esac
}

OS=$(detect_os)
ARCH=$(detect_arch)

if [ "$OS" = "unknown" ] || [ "$ARCH" = "unknown" ]; then
    echo "Error: Unsupported platform: $OS $ARCH"
    exit 1
fi

echo "Detected platform: $OS $ARCH"

cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)"

echo "Building core library..."
cd build_core
cargo build --release

echo "Building CLI tool..."
cd ../build_manager_cli
cargo build --release
cargo install --path .

echo "Build Manager CLI installed successfully!"
echo ""
echo "Run 'soliloquy-build --help' to get started"
echo ""
echo "To build the GUI application:"
echo "  cd $PROJECT_ROOT/build_manager_gui"
echo "  npm install"
echo "  npm run tauri:build"
