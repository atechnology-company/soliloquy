#!/bin/bash
# build_sdk.sh - Build Soliloquy using Fuchsia SDK
# Usage: ./tools/soliloquy/build_sdk.sh [--cpu CPU] [--debug]

set -e

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/build_common.sh"

# Default values
CPU="arm64"
IS_DEBUG=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --cpu)
            CPU="$2"
            shift 2
            ;;
        --debug)
            IS_DEBUG=true
            shift
            ;;
        --release)
            IS_DEBUG=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--cpu CPU] [--debug|--release]"
            echo ""
            echo "Build Soliloquy using Fuchsia SDK."
            echo ""
            echo "Options:"
            echo "  --cpu CPU           Target CPU (default: arm64)"
            echo "  --debug             Build debug version (default)"
            echo "  --release           Build release version"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                  # Build debug arm64"
            echo "  $0 --cpu x64        # Build debug x64"
            echo "  $0 --release        # Build release arm64"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

log_info "=== Soliloquy SDK Build ==="
log_info "CPU: $CPU"
log_info "Build Type: $([ "$IS_DEBUG" = true ] && echo "Debug" || echo "Release")"

# Check SDK
if [ ! -d "$SDK_DIR/tools" ]; then
    log_error "SDK not found. Run ./tools/soliloquy/setup_sdk.sh first"
    exit 1
fi

export PATH="$SDK_DIR/tools:$PATH"

# Generate build files
log_info "Generating build files..."
OUTPUT_DIR="out/$CPU"
GN_ARGS="target_cpu=\"$CPU\" target_os=\"fuchsia\" is_debug=$IS_DEBUG"

gn gen "$OUTPUT_DIR" --args="$GN_ARGS"

# Build
log_info "Building..."
ninja -C "$OUTPUT_DIR"

# Emit artifact summary
emit_artifact_summary "Fuchsia SDK Build" "$OUTPUT_DIR"
