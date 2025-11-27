#!/usr/bin/env bash
# Zircon-specific utilities for Soliloquy
# These scripts only work on Fuchsia/Zircon targets

# Check if we're on Fuchsia
assert_fuchsia() {
    if ! [[ -d "/svc" && -d "/dev/class" ]]; then
        echo "Error: This script must run on Fuchsia/Zircon" >&2
        exit 1
    fi
}

# Query scenic for display info
query_scenic_displays() {
    assert_fuchsia
    
    local display_count=0
    
    # List display devices
    if [[ -d "/dev/class/display" ]]; then
        for device in /dev/class/display/*; do
            if [[ -e "$device" ]]; then
                echo "Display device: $device"
                ((display_count++))
            fi
        done
    fi
    
    echo "Total displays: $display_count"
    
    # Check scenic service availability
    if [[ -e "/svc/fuchsia.ui.display.singleton.Info" ]]; then
        echo "Scenic display info service: available"
    else
        echo "Scenic display info service: not available"
    fi
    
    if [[ -e "/svc/fuchsia.ui.composition.Flatland" ]]; then
        echo "Flatland compositor: available"
    else
        echo "Flatland compositor: not available"
    fi
    
    return $([[ $display_count -gt 0 ]] && echo 0 || echo 1)
}

# List available FIDL services
list_fidl_services() {
    assert_fuchsia
    
    echo "Available FIDL services in /svc:"
    ls -la /svc/ 2>/dev/null | grep fuchsia || echo "  (none found)"
}

# Check Zircon kernel info
show_kernel_info() {
    assert_fuchsia
    
    if [[ -f "/boot/kernel/vdso/full" ]]; then
        echo "Zircon VDSO: present"
    fi
    
    # Show memory info if available
    if command -v kstats &> /dev/null; then
        echo "Memory stats:"
        kstats 2>/dev/null | head -10
    fi
}

# Launch component
launch_component() {
    assert_fuchsia
    
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo "Usage: launch_component <component_url>" >&2
        return 1
    fi
    
    echo "Launching: $url"
    ffx component run "$url" 2>/dev/null || \
        run "$url" 2>/dev/null || \
        echo "Failed to launch component"
}

# Get device info
get_device_info() {
    assert_fuchsia
    
    echo "Device Information:"
    echo "  Board: $(cat /config/build-info/board 2>/dev/null || echo 'unknown')"
    echo "  Product: $(cat /config/build-info/product 2>/dev/null || echo 'unknown')"
    echo "  Version: $(cat /config/build-info/version 2>/dev/null || echo 'unknown')"
}
