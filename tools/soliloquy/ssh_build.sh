#!/bin/bash
# ssh_build.sh - Run Soliloquy build on remote host
# Usage: ./tools/soliloquy/ssh_build.sh [options] <host>
#
# Options:
#   --remote-dir PATH    Remote directory path (default: auto-detect)
#   --local-dir PATH     Local directory to sync from (default: current)
#   --no-sync           Skip rsync and use existing remote checkout
#   --stream-logs       Stream build logs in real-time
#   --product PRODUCT   Product to build (default: minimal.arm64)
#   --board BOARD       Board configuration (default: boards/arm64/soliloquy)
#   --help, -h          Show help

set -e

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/build_common.sh"

# Default values
REMOTE_DIR=""
LOCAL_DIR="$(pwd)"
NO_SYNC=false
STREAM_LOGS=false
PRODUCT="$DEFAULT_PRODUCT"
BOARD="$BOARD_PATH"
REMOTE_HOST=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --remote-dir)
            REMOTE_DIR="$2"
            shift 2
            ;;
        --local-dir)
            LOCAL_DIR="$2"
            shift 2
            ;;
        --no-sync)
            NO_SYNC=true
            shift
            ;;
        --stream-logs)
            STREAM_LOGS=true
            shift
            ;;
        --product)
            PRODUCT="$2"
            shift 2
            ;;
        --board)
            BOARD="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options] <host>"
            echo ""
            echo "Run Soliloquy build on remote host with improved macOS support."
            echo ""
            echo "Arguments:"
            echo "  host                Remote SSH host (user@hostname)"
            echo ""
            echo "Options:"
            echo "  --remote-dir PATH   Remote directory path (default: auto-detect)"
            echo "  --local-dir PATH    Local directory to sync from (default: current)"
            echo "  --no-sync          Skip rsync and use existing remote checkout"
            echo "  --stream-logs      Stream build logs in real-time"
            echo "  --product PRODUCT  Product to build (default: $DEFAULT_PRODUCT)"
            echo "  --board BOARD      Board configuration (default: $BOARD_PATH)"
            echo "  --help, -h         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 user@linux-server                    # Auto-detect paths"
            echo "  $0 --stream-logs user@linux-server      # Stream logs live"
            echo "  $0 --no-sync --product workbench.arm64 user@linux-server"
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            if [ -z "$REMOTE_HOST" ]; then
                REMOTE_HOST="$1"
            else
                log_error "Multiple hosts specified: $REMOTE_HOST and $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if remote host is specified
if [ -z "$REMOTE_HOST" ]; then
    log_error "Remote host is required"
    echo "Usage: $0 [options] <host>"
    echo "Use --help for more information"
    exit 1
fi

# Auto-detect remote directory if not specified
if [ -z "$REMOTE_DIR" ]; then
    # Try common mount paths for macOS
    REMOTE_DIR="/Volumes/storage/GitHub/soliloquy"
    
    # Check if the auto-detected path exists on remote
    if ! ssh "$REMOTE_HOST" "test -d '$REMOTE_DIR'" 2>/dev/null; then
        # Try alternative paths
        for alt_path in "/mnt/mac/Volumes/storage/GitHub/soliloquy" "/home/$(ssh "$REMOTE_HOST" whoami)/soliloquy" "/tmp/soliloquy"; do
            if ssh "$REMOTE_HOST" "test -d '$alt_path'" 2>/dev/null; then
                REMOTE_DIR="$alt_path"
                break
            fi
        done
        
        # If still not found, use a reasonable default
        if ! ssh "$REMOTE_HOST" "test -d '$REMOTE_DIR'" 2>/dev/null; then
            log_warning "Auto-detected remote directory not found, using: $REMOTE_DIR"
            log_info "You may need to specify --remote-dir if this is incorrect"
        fi
    fi
fi

log_info "=== Soliloquy Remote Build ==="
log_info "Remote Host: $REMOTE_HOST"
log_info "Remote Directory: $REMOTE_DIR"
log_info "Local Directory: $LOCAL_DIR"
log_info "Product: $PRODUCT"
log_info "Board: $BOARD"

# Verify remote directory exists
if ! ssh "$REMOTE_HOST" "test -d '$REMOTE_DIR'"; then
    log_error "Remote directory does not exist: $REMOTE_DIR"
    log_info "Ensure the directory is accessible on the remote host or specify --remote-dir"
    exit 1
fi

# Sync source if needed
if [ "$NO_SYNC" = false ]; then
    log_info "Syncing source to remote host..."
    rsync -avz --progress \
        --exclude='.git' \
        --exclude='out' \
        --exclude='bazel-*' \
        --exclude='fuchsia/out' \
        --exclude='*.pyc' \
        --exclude='__pycache__' \
        "$LOCAL_DIR/" "$REMOTE_HOST:$REMOTE_DIR/"
else
    log_info "Skipping sync - using existing remote checkout"
fi

# Prepare remote build command
REMOTE_BUILD_CMD="cd '$REMOTE_DIR' && source ./tools/soliloquy/lib/build_common.sh"

# Ensure fx-env.sh is sourced before running fx commands
REMOTE_BUILD_CMD="$REMOTE_BUILD_CMD && ./tools/soliloquy/build.sh --product '$PRODUCT' --board '$BOARD'"

# Execute build
log_info "Triggering remote build..."
if [ "$STREAM_LOGS" = true ]; then
    log_info "Streaming build logs in real-time..."
    ssh -t "$REMOTE_HOST" "$REMOTE_BUILD_CMD"
else
    log_info "Running build remotely (logs will be shown at completion)..."
    ssh -t "$REMOTE_HOST" "$REMOTE_BUILD_CMD"
fi

log_success "Remote build completed!"
log_info "Artifacts are available in: $REMOTE_DIR/fuchsia/fuchsia/out/default"
