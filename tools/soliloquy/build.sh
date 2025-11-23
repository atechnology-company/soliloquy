#!/bin/bash
# build.sh - Build Soliloquy OS
# Usage: ./tools/soliloquy/build.sh [--product PRODUCT] [--board BOARD] [--extra-args ARGS]

set -e

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/build_common.sh"

# Default values
PRODUCT="$DEFAULT_PRODUCT"
BOARD="$BOARD_PATH"
EXTRA_ARGS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --product)
            PRODUCT="$2"
            shift 2
            ;;
        --board)
            BOARD="$2"
            shift 2
            ;;
        --extra-args)
            EXTRA_ARGS="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--product PRODUCT] [--board BOARD] [--extra-args ARGS]"
            echo ""
            echo "Build Soliloquy OS with configurable product and board."
            echo ""
            echo "Options:"
            echo "  --product PRODUCT     Product to build (default: $DEFAULT_PRODUCT)"
            echo "  --board BOARD         Board configuration (default: $BOARD_PATH)"
            echo "  --extra-args ARGS     Additional arguments to pass to fx set"
            echo "  --help, -h            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Build with defaults"
            echo "  $0 --product workbench_eng.arm64     # Build different product"
            echo "  $0 --board boards/arm64/qemu          # Build for different board"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

log_info "=== Soliloquy OS Build ==="
log_info "Product: $PRODUCT"
log_info "Board: $BOARD"

# Check if fx is available and bootstrapped
check_fx_bootstrapped

# Validate component manifests before building
log_info "Validating component manifests..."
if [ -x "$SCRIPT_DIR/validate_manifest.sh" ]; then
    if "$SCRIPT_DIR/validate_manifest.sh"; then
        log_success "Manifest validation passed"
    else
        log_error "Manifest validation failed"
        exit 1
    fi
else
    log_warning "validate_manifest.sh not found or not executable, skipping validation"
fi

# Idempotent configuration
fx_set_idempotent "$PRODUCT" "$BOARD" "$EXTRA_ARGS"

# Build
log_info "Starting build..."
cd "$FUCHSIA_DIR"
fx build

# Emit artifact summary
OUTPUT_DIR=$(get_output_dir "fuchsia")
emit_artifact_summary "Fuchsia Full Source Build" "$OUTPUT_DIR"
