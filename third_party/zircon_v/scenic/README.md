# Zircon Scenic Bindings

V language bindings for Zircon's Scenic display and compositor services.

## Overview

This module provides native FIDL bindings for:

- **fuchsia.ui.display.singleton.Info** - Display detection and metrics
- **fuchsia.ui.composition.Flatland** - UI composition and rendering

## Files

| File | Description |
|------|-------------|
| `scenic_types.v` | Core types: DisplayMetrics, DisplayInfo, LayoutInfo |
| `display.v` | Display detection via device tree and FIDL |
| `flatland.v` | Flatland compositor client bindings |

## Usage

### Display Detection

```v
import scenic

// Detect all connected displays
result := scenic.detect_displays()

if result.query_result == .success {
    for display in result.displays {
        println(display.format())
    }
}

// Quick check for any display
if scenic.has_display() {
    println('Desktop mode')
} else {
    println('Headless mode')
}

// Get primary display
if primary := scenic.get_primary_display() {
    println('Primary: ${primary.metrics.extent_in_px_width}x${primary.metrics.extent_in_px_height}')
}
```

### Flatland Compositor

```v
import scenic

// Connect to Flatland
mut client := scenic.FlatlandClient.new() or {
    eprintln('Failed to connect to Flatland')
    return
}
defer { client.close() }

// Create transforms
root := client.create_transform() or { return }
client.set_root_transform(root)

// Get layout info
if layout := client.get_layout() {
    println('Layout: ${layout.logical_size.width}x${layout.logical_size.height}')
}

// Present changes
client.present(scenic.PresentArgs{
    requested_presentation_time: 0
    unsquashable: false
})
```

## FIDL Protocol References

- [fuchsia.ui.display.singleton](../../../sdk/fidl/fuchsia.ui.display.singleton/)
- [fuchsia.ui.composition](../../../sdk/fidl/fuchsia.ui.composition/)

## Device Tree

On Fuchsia, displays are enumerated via:
- `/dev/class/display/` - Display controller devices
- `/svc/fuchsia.ui.display.singleton.Info` - Scenic display info service

## Build

```bash
bazel build //third_party/zircon_v/scenic:scenic
bazel test //third_party/zircon_v/scenic:scenic_test
```
