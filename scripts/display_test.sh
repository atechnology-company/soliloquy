#!/usr/bin/env bash
# Soliloquy Display Detection Test
# Tests display detection on Fuchsia/Zircon or simulates headless mode
#
# Usage: ./scripts/display_test.sh [options]
#
# Options:
#   --simulate-headless   Force headless mode simulation
#   --simulate-display    Force display mode simulation
#   --json                Output JSON format
#   --verbose             Verbose output
#   --help                Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source shared library
source "${SCRIPT_DIR}/lib/common.sh"

# Defaults
SIMULATE_HEADLESS=false
SIMULATE_DISPLAY=false
JSON_OUTPUT=false
VERBOSE=false

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --simulate-headless)
            SIMULATE_HEADLESS=true
            shift
            ;;
        --simulate-display)
            SIMULATE_DISPLAY=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            head -16 "$0" | tail -n +2 | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Detect if we're on Fuchsia
is_fuchsia() {
    [[ -d "/svc" ]] && [[ -d "/dev/class" ]]
}

# Check for display on Fuchsia
check_fuchsia_display() {
    local display_count=0
    local display_info=""
    
    # Check /dev/class/display/
    if [[ -d "/dev/class/display" ]]; then
        for device in /dev/class/display/*; do
            if [[ -e "$device" ]]; then
                ((display_count++))
                display_info="${display_info}${device}\n"
            fi
        done
    fi
    
    # Check scenic service
    local scenic_available=false
    if [[ -e "/svc/fuchsia.ui.display.singleton.Info" ]]; then
        scenic_available=true
    fi
    
    if $JSON_OUTPUT; then
        echo "{"
        echo "  \"platform\": \"fuchsia\","
        echo "  \"display_count\": $display_count,"
        echo "  \"scenic_available\": $scenic_available,"
        echo "  \"mode\": \"$([ $display_count -gt 0 ] && echo 'desktop' || echo 'headless')\""
        echo "}"
    else
        log_info "Platform: Fuchsia/Zircon"
        log_info "Displays found: $display_count"
        log_info "Scenic service: $scenic_available"
        
        if [[ $display_count -gt 0 ]]; then
            log_success "Mode: DESKTOP"
            log_info "Servo + V8 will render UI"
        else
            log_success "Mode: HEADLESS"
            log_info "Running as Cupboard sync server only"
        fi
    fi
    
    return $([[ $display_count -gt 0 ]] && echo 0 || echo 1)
}

# Check display on development host (macOS/Linux)
check_host_display() {
    local has_display=false
    local display_info=""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - check system_profiler
        if system_profiler SPDisplaysDataType 2>/dev/null | grep -q "Resolution"; then
            has_display=true
            display_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -E "Resolution|Display Type" | head -4)
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux - check xrandr or drm
        if command -v xrandr &> /dev/null && xrandr 2>/dev/null | grep -q " connected"; then
            has_display=true
            display_info=$(xrandr 2>/dev/null | grep " connected" | head -4)
        elif [[ -d "/sys/class/drm" ]]; then
            for connector in /sys/class/drm/card*/status; do
                if [[ -f "$connector" ]] && grep -q "connected" "$connector"; then
                    has_display=true
                    break
                fi
            done
        fi
    fi
    
    if $JSON_OUTPUT; then
        echo "{"
        echo "  \"platform\": \"host\","
        echo "  \"os\": \"$OSTYPE\","
        echo "  \"display_detected\": $has_display,"
        echo "  \"note\": \"Dev mode - display detection for testing only\""
        echo "}"
    else
        log_info "Platform: Development Host ($OSTYPE)"
        log_info "Display detected: $has_display"
        
        if $VERBOSE && [[ -n "$display_info" ]]; then
            log_info "Display info:"
            echo "$display_info" | sed 's/^/  /'
        fi
        
        log_info ""
        log_info "Note: On Fuchsia, display detection uses Zircon scenic service"
    fi
}

# Test via backend API
test_backend_api() {
    log_info "Testing display detection via backend API..."
    
    local backend_url="http://localhost:3030"
    
    if ! curl -s "${backend_url}/health" > /dev/null 2>&1; then
        log_error "Backend not running. Start with: ./scripts/dev.sh --backend-only"
        return 1
    fi
    
    local response=$(curl -s "${backend_url}/api/display/info")
    
    if $JSON_OUTPUT; then
        echo "$response"
    else
        log_info "Backend display detection response:"
        echo "$response" | jq . 2>/dev/null || echo "$response"
        
        local mode=$(echo "$response" | jq -r '.mode' 2>/dev/null)
        if [[ "$mode" == "desktop" ]]; then
            log_success "Backend reports: DESKTOP mode"
        elif [[ "$mode" == "headless" ]]; then
            log_success "Backend reports: HEADLESS mode"
        else
            log_info "Backend reports mode: $mode"
        fi
    fi
}

# Simulate modes for testing
simulate_mode() {
    if $SIMULATE_HEADLESS; then
        if $JSON_OUTPUT; then
            echo '{"simulated": true, "mode": "headless", "display_count": 0}'
        else
            log_info "🧪 SIMULATING HEADLESS MODE"
            log_info ""
            log_info "In this mode, Soliloquy runs as:"
            log_info "  - Cupboard sync server"
            log_info "  - REST API at http://localhost:3030"
            log_info "  - No Servo/V8 desktop rendering"
            log_info ""
            log_info "Other devices can sync via:"
            log_info "  POST /api/sync/push"
            log_info "  POST /api/sync/pull"
        fi
        return 0
    fi
    
    if $SIMULATE_DISPLAY; then
        if $JSON_OUTPUT; then
            echo '{"simulated": true, "mode": "desktop", "display_count": 1, "resolution": "1920x1080"}'
        else
            log_info "🧪 SIMULATING DESKTOP MODE"
            log_info ""
            log_info "In this mode, Soliloquy runs as:"
            log_info "  - Full desktop environment"
            log_info "  - Servo + V8 rendering"
            log_info "  - Svelte 5 UI"
            log_info "  - Cupboard sync + local storage"
            log_info ""
            log_info "Display: 1920x1080 @ 60Hz (simulated)"
        fi
        return 0
    fi
    
    return 1
}

# Main
main() {
    if ! $JSON_OUTPUT; then
        log_info "=== Soliloquy Display Detection Test ==="
        log_info ""
    fi
    
    # Check for simulation
    if simulate_mode; then
        exit 0
    fi
    
    # Real detection
    if is_fuchsia; then
        check_fuchsia_display
    else
        check_host_display
        
        # Also test via backend if running
        if curl -s "http://localhost:3030/health" > /dev/null 2>&1; then
            echo ""
            test_backend_api
        fi
    fi
}

main
