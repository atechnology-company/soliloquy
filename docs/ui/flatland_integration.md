# Flatland Window Integration

## Overview

This document describes the Flatland window integration implemented in the Soliloquy shell. The shell now acts as a ViewProvider backed by Flatland, enabling it to participate in Fuchsia's UI composition system.

## Components

### 1. ZirconWindow (`src/shell/zircon_window.rs`)

The `ZirconWindow` struct manages the Flatland connection and scene graph:

```rust
pub struct ZirconWindow {
    flatland: flatland::FlatlandProxy,
    root_transform_id: flatland::TransformId,
    content_transform_id: flatland::TransformId,
    view_creation_token: Option<views::ViewCreationToken>,
}
```

**Key methods:**
- `new()` - Creates a window with a new Flatland connection
- `new_with_view_token(token)` - Creates a window with a ViewCreationToken (for ViewProvider)
- `setup_scene_graph()` - Initializes the Flatland scene graph (transforms, content)
- `present()` - Presents the current frame to the compositor

**Features:**
- Connects to `fuchsia.ui.composition.Flatland` protocol
- Creates root and content transform IDs for scene graph hierarchy
- Stores view tokens for integration with parent views
- Conditional compilation with `#[cfg(feature = "fuchsia")]` for host builds

### 2. ViewProvider Server (`src/shell/main.rs`)

The shell exposes `fuchsia.ui.app.ViewProvider` service via ServiceFs:

```rust
enum IncomingService {
    ViewProvider(ViewProviderRequestStream),
}
```

**Implementation:**
- Registers ViewProvider service with ServiceFs
- Handles both `CreateView` (legacy) and `CreateView2` requests
- Creates ZirconWindow instances with view tokens
- Sets up Flatland scene graph for each view

**Service flow:**
1. Component starts and registers ViewProvider with ServiceFs
2. Parent component connects to ViewProvider protocol
3. Parent calls CreateView2 with ViewCreationToken
4. Shell creates ZirconWindow with token and sets up scene graph
5. Flatland session is now connected to parent's view hierarchy

### 3. FIDL Bindings

**Generated crates:**
- `fuchsia_ui_composition` - Flatland API (FlatlandProxy, TransformId, ContentId)
- `fuchsia_ui_views` - View tokens (ViewCreationToken, ViewportCreationToken)
- `fuchsia_ui_app` - ViewProvider protocol (ViewProviderRequestStream, CreateView2Args)
- `fuchsia_input` - Input event types

**Location:** `gen/fidl/`

### 4. Fuchsia SDK Crates

**Placeholder implementations in `third_party/fuchsia-sdk-rust/`:**
- `fuchsia-async` - Async executor (wraps `futures::executor`)
- `fuchsia-component` - Component client/server APIs
- `fuchsia-syslog` - Logging (wraps `env_logger`)
- `fidl` - FIDL runtime types and traits

These are minimal implementations for development/testing without full SDK.

## Build Configuration

### Cargo.toml

```toml
[features]
default = []
fuchsia = []

[dependencies]
fuchsia-async = { path = "../../third_party/fuchsia-sdk-rust/fuchsia-async" }
fuchsia-component = { path = "../../third_party/fuchsia-sdk-rust/fuchsia-component" }
fuchsia-syslog = { path = "../../third_party/fuchsia-sdk-rust/fuchsia-syslog" }
fuchsia_ui_composition = { path = "../../gen/fidl/fuchsia_ui_composition" }
fuchsia_ui_views = { path = "../../gen/fidl/fuchsia_ui_views" }
fuchsia_ui_app = { path = "../../gen/fidl/fuchsia_ui_app" }
fuchsia_input = { path = "../../gen/fidl/fuchsia_input" }
```

### BUILD.gn

```gn
deps = [
  "//gen/fidl/fuchsia_ui_composition",
  "//gen/fidl/fuchsia_ui_views",
  "//gen/fidl/fuchsia_ui_app",
  "//gen/fidl/fuchsia_input",
  # ... other deps
]
```

### BUILD.bazel

```python
deps = [
    "//gen/fidl/fuchsia_ui_composition",
    "//gen/fidl/fuchsia_ui_views",
    "//gen/fidl/fuchsia_ui_app",
    "//gen/fidl/fuchsia_input",
    # ... other deps
],
```

## Component Manifest

`meta/soliloquy_shell.cml` declares:

**Capabilities:**
```json
{
  "protocol": [ "fuchsia.ui.app.ViewProvider" ]
}
```

**Use:**
```json
{
  "protocol": [
    "fuchsia.ui.composition.Flatland",
    "fuchsia.ui.composition.Allocator",
    "fuchsia.ui.views.ViewRefInstalled",
    // ... input protocols
  ]
}
```

**Expose:**
```json
{
  "protocol": [ "fuchsia.ui.app.ViewProvider" ],
  "from": "self"
}
```

## Usage

### Building

```bash
# GN build
fx build //src/shell:soliloquy_shell

# Bazel build
bazel build //src/shell:soliloquy_shell
```

### Running

```bash
# Start the component
ffx component run /core/soliloquy_shell fuchsia-pkg://fuchsia.com/soliloquy_shell#meta/soliloquy_shell.cm
```

### Connecting as a View

Other components can embed the shell as a view:

```rust
use fuchsia_ui_app::ViewProviderMarker;
use fuchsia_component::client::connect_to_protocol;

let view_provider = connect_to_protocol::<ViewProviderMarker>()?;

// Create view token pair
let (view_token, viewport_token) = create_view_tokens()?;

// Request view creation
view_provider.create_view2(CreateView2Args {
    view_creation_token: view_token,
})?;

// Use viewport_token to attach to your Flatland session
```

## Implementation Notes

### Feature Gating

All Fuchsia-specific code is gated with `#[cfg(feature = "fuchsia")]`:

```rust
#[cfg(feature = "fuchsia")]
use fuchsia_ui_composition::fidl_fuchsia_ui_composition as flatland;

#[cfg(not(feature = "fuchsia"))]
pub struct ZirconWindow {} // Placeholder for host builds
```

This allows the code to compile for host development without Fuchsia SDK.

### Placeholder Implementations

The current implementation uses placeholder FIDL bindings and SDK crates. These provide the correct types and trait signatures but don't make actual FIDL calls. To use real Fuchsia SDK:

1. Run `./tools/soliloquy/setup_sdk.sh` to download SDK
2. Run `./tools/soliloquy/gen_fidl_bindings.sh` to generate real bindings
3. Replace placeholder SDK crates with actual SDK libraries

### Logging

All operations are logged using the `log` crate (info/debug/error):

```rust
info!("Creating ZirconWindow with Flatland connection");
info!("Received CreateView2 request");
error!("ViewProvider request error: {:?}", e);
```

Logs go to syslog via `fuchsia-syslog` (or stderr on host builds).

## Testing

### Integration Tests

Verify ViewProvider service is exposed:

```bash
ffx component show /core/soliloquy_shell
# Should list "fuchsia.ui.app.ViewProvider" in exposed protocols
```

### Logging

Enable debug logging to see Flatland calls:

```bash
ffx log --filter soliloquy
```

Expected log messages:
- "Creating ZirconWindow with Flatland connection"
- "Connected to Flatland protocol"
- "Creating Flatland transforms: root=..., content=..."
- "Received CreateView2 request"
- "Setting up Flatland scene graph"

## Future Work

1. **Real Flatland calls:** Replace placeholder implementations with actual FIDL protocol calls:
   - `flatland.CreateTransform()`
   - `flatland.SetContent()`
   - `flatland.SetRootTransform()`
   - `flatland.Present()`

2. **Buffer allocation:** Integrate with `fuchsia.ui.composition.Allocator` for image buffers

3. **Input handling:** Wire touch/keyboard events to Servo embedder

4. **View lifecycle:** Handle view detachment and cleanup

5. **Error handling:** Improve error propagation and recovery

## References

- [Fuchsia UI Documentation](https://fuchsia.dev/fuchsia-src/concepts/ui)
- [Flatland Protocol](https://fuchsia.dev/reference/fidl/fuchsia.ui.composition)
- [ViewProvider Protocol](https://fuchsia.dev/reference/fidl/fuchsia.ui.app)
- `docs/ui/flatland_bindings.md` - FIDL bindings generation guide
