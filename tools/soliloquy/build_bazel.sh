#!/bin/bash
# build_bazel.sh - Build Soliloquy using Bazel
# Usage: ./tools/soliloquy/build_bazel.sh [target] [options]

set -e

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/build_common.sh"

# Default values
TARGET="//..."
BAZEL_ARGS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --target)
            TARGET="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--target TARGET] [bazel_options]"
            echo ""
            echo "Build Soliloquy using Bazel."
            echo ""
            echo "Arguments:"
            echo "  --target TARGET     Bazel target to build (default: //...)"
            echo "  bazel_options       Additional options to pass to bazel build"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                      # Build all targets"
            echo "  $0 --target //src/shell:soliloquy_shell # Build specific target"
            echo "  $0 --target //src/shell:soliloquy_shell -- -c opt  # Build optimized"
            exit 0
            ;;
        --*)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            # Pass remaining arguments to bazel
            BAZEL_ARGS="$BAZEL_ARGS $1"
            shift
            ;;
    esac
done

log_info "=== Soliloquy Bazel Build ==="
log_info "Target: $TARGET"
if [ -n "$BAZEL_ARGS" ]; then
    log_info "Additional Args: $BAZEL_ARGS"
fi

# Check SDK
if [ ! -d "$SDK_DIR" ]; then
    log_error "SDK not found. Run ./tools/soliloquy/setup_sdk.sh first"
    exit 1
fi

# Build
log_info "Building..."
bazel build $TARGET $BAZEL_ARGS

# Emit artifact summary
OUTPUT_DIR=$(get_output_dir "bazel")
emit_artifact_summary "Bazel Build" "$OUTPUT_DIR"
