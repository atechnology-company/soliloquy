#!/usr/bin/env bash
# Soliloquy Development Mode
# Starts backend and UI with hot reload
#
# Usage: ./scripts/dev.sh [options]
#
# Options:
#   --backend-only   Start only the backend (headless mode)
#   --ui-only        Start only the UI dev server
#   --port PORT      Backend port (default: 3030)
#   --help           Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source shared library
source "${SCRIPT_DIR}/lib/common.sh"

# Defaults
BACKEND_ONLY=false
UI_ONLY=false
PORT=3030
BACKEND_PID=""
UI_PID=""

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --backend-only)
            BACKEND_ONLY=true
            shift
            ;;
        --ui-only)
            UI_ONLY=true
            shift
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --help|-h)
            head -14 "$0" | tail -n +2 | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Cleanup on exit
cleanup() {
    log_info "Stopping Soliloquy dev mode..."
    
    if [[ -n "$UI_PID" ]]; then
        kill "$UI_PID" 2>/dev/null || true
    fi
    
    if [[ -n "$BACKEND_PID" ]]; then
        kill "$BACKEND_PID" 2>/dev/null || true
    fi
    
    # Clean up PID files
    rm -f /tmp/soliloquy-backend.pid /tmp/soliloquy-ui.pid
    
    log_success "Stopped"
}

trap cleanup EXIT INT TERM

# Start backend
start_backend() {
    log_info "Starting V backend on port $PORT..."
    
    cd "${PROJECT_ROOT}/backend"
    
    if ! command -v v &> /dev/null; then
        log_error "V compiler not found. Install from https://vlang.io"
        exit 1
    fi
    
    # Load .env if exists
    if [[ -f .env ]]; then
        log_info "Loading .env configuration"
        set -a
        source .env
        set +a
    fi
    
    # Start backend with watch mode if available
    if v help 2>&1 | grep -q "watch"; then
        v watch run . &
    else
        v run . &
    fi
    BACKEND_PID=$!
    echo "$BACKEND_PID" > /tmp/soliloquy-backend.pid
    
    # Wait for backend
    log_info "Waiting for backend..."
    for i in {1..30}; do
        if curl -s "http://localhost:${PORT}/health" > /dev/null 2>&1; then
            log_success "Backend ready at http://localhost:${PORT}"
            return 0
        fi
        sleep 1
    done
    
    log_error "Backend failed to start"
    exit 1
}

# Start UI dev server
start_ui() {
    log_info "Starting Svelte UI dev server..."
    
    cd "${PROJECT_ROOT}/ui/desktop"
    
    if ! command -v pnpm &> /dev/null; then
        log_error "pnpm not found. Install with: corepack enable pnpm"
        exit 1
    fi
    
    # Install deps if needed
    if [[ ! -d node_modules ]]; then
        log_info "Installing UI dependencies..."
        pnpm install
    fi
    
    pnpm dev &
    UI_PID=$!
    echo "$UI_PID" > /tmp/soliloquy-ui.pid
    
    log_success "UI dev server started"
    log_success "🚀 Open http://localhost:5173"
}

# Main
main() {
    log_info "🌟 Soliloquy Development Mode"
    
    if $UI_ONLY; then
        start_ui
    elif $BACKEND_ONLY; then
        start_backend
    else
        start_backend
        start_ui
    fi
    
    echo ""
    log_success "✨ Development servers running"
    log_info "Backend: http://localhost:${PORT}"
    if ! $BACKEND_ONLY; then
        log_info "Frontend: http://localhost:5173"
    fi
    log_info ""
    log_info "Press Ctrl+C to stop"
    
    wait
}

main
