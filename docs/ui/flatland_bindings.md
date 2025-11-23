# Flatland FIDL Bindings

This document describes the generated Rust bindings for Fuchsia UI FIDL protocols and how to use them in Soliloquy Shell, particularly for Flatland compositor integration.

## Overview

Soliloquy generates local Rust bindings for the following Fuchsia FIDL libraries:

- **fuchsia.ui.composition** - Flatland compositor API for modern scene graph rendering
- **fuchsia.ui.views** - View tokens, ViewRef, and view provider protocols
- **fuchsia.input** - Input event handling (keyboard, mouse, touch)

These bindings are generated from FIDL definitions in the Fuchsia SDK and checked into the repository under `gen/fidl/`. This approach provides:

1. **Build independence**: No need for SDK-prebuilt crates during development
2. **Version control**: Exact API versions are tracked in git
3. **Cross-build support**: Works with GN, Bazel, and Cargo builds
4. **Transparency**: Generated code is readable and debuggable

## Generated Structure

```
gen/fidl/
├── BUILD.gn                          # Top-level GN build file
├── BUILD.bazel                       # Top-level Bazel build file
├── README.md                         # Generated bindings overview
├── fuchsia_ui_composition/
│   ├── BUILD.gn                      # GN library target
│   ├── BUILD.bazel                   # Bazel library target
│   ├── Cargo.toml                    # Cargo package manifest
│   ├── README.md                     # Library-specific docs
│   └── src/
│       └── lib.rs                    # Generated Rust bindings
├── fuchsia_ui_views/
│   └── ...                           # Similar structure
└── fuchsia_input/
    └── ...                           # Similar structure
```

Each crate is self-contained with its own build configuration for all three build systems.

## Regenerating Bindings

To regenerate the FIDL bindings after updating the Fuchsia SDK:

### Prerequisites

1. Fuchsia SDK must be installed:
   ```bash
   ./tools/soliloquy/setup_sdk.sh
   ```

2. Set up the environment:
   ```bash
   source tools/soliloquy/env.sh
   ```

### Running the Generator

```bash
./tools/soliloquy/gen_fidl_bindings.sh
```

The script will:
1. Source `tools/soliloquy/env.sh` to locate the SDK
2. Find `fidlc` and `fidlgen_rust` tools
3. Compile FIDL definitions to JSON IR
4. Generate Rust bindings from IR
5. Create/update crate structure with build files

### Environment Variables

The generation script uses the following environment variables:

- **FUCHSIA_DIR**: Path to Fuchsia SDK or full source checkout (set automatically by `env.sh`)
- **CLANG_HOST_ARCH**: Host architecture for toolchain (linux-x64 or mac-x64)
- **FUCHSIA_SDK_VERSION**: (Optional) Pin specific SDK version

### Checking in Generated Code

Generated code is checked into git to ensure reproducible builds. After regeneration:

```bash
git add gen/fidl/
git commit -m "Update FIDL bindings to SDK version X.Y.Z"
```

## Using the Bindings

### In Rust (Cargo)

Add to your `Cargo.toml`:

```toml
[dependencies]
fuchsia_ui_composition = { path = "../../gen/fidl/fuchsia_ui_composition" }
fuchsia_ui_views = { path = "../../gen/fidl/fuchsia_ui_views" }
fuchsia_input = { path = "../../gen/fidl/fuchsia_input" }
```

Then import in your Rust code:

```rust
use fuchsia_ui_composition::{FlatlandProxy, TransformId, ContentId};
use fuchsia_ui_views::{ViewCreationToken, ViewRef};
use fuchsia_input::{KeyEvent, TouchEvent};
```

### In GN Build

Add to your `BUILD.gn` deps:

```gn
deps = [
  "//gen/fidl/fuchsia_ui_composition",
  "//gen/fidl/fuchsia_ui_views",
  "//gen/fidl/fuchsia_input",
]
```

### In Bazel Build

Add to your `BUILD.bazel` deps:

```python
deps = [
    "//gen/fidl/fuchsia_ui_composition",
    "//gen/fidl/fuchsia_ui_views",
    "//gen/fidl/fuchsia_input",
]
```

## Flatland API Examples

### Creating a Flatland Session

```rust
use fuchsia_ui_composition::{
    FlatlandProxy, FlatlandMarker, TransformId, ContentId,
    ImageProperties, Vec2, PresentArgs,
};
use fuchsia_ui_views::{ViewCreationToken, ViewRef};
use fidl::endpoints::create_proxy;

async fn create_flatland_session() -> Result<FlatlandProxy, fidl::Error> {
    // Connect to Flatland service
    let (flatland, server_end) = create_proxy::<FlatlandMarker>()?;
    
    // In a real implementation, server_end would be connected to the compositor
    // via component framework service discovery
    
    Ok(flatland)
}
```

### Building a Scene Graph

```rust
use fuchsia_ui_composition::{TransformId, ContentId, Vec2};

fn setup_scene(flatland: &FlatlandProxy) {
    // Create root transform
    let root_transform = TransformId::new(1);
    flatland.create_transform(&root_transform).await.ok();
    
    // Set as root
    flatland.set_root_transform(&root_transform).await.ok();
    
    // Create child transform for content
    let content_transform = TransformId::new(2);
    flatland.create_transform(&content_transform).await.ok();
    
    // Add child to root
    flatland.add_child(&root_transform, &content_transform).await.ok();
    
    // Position the content
    flatland.set_translation(&content_transform, &Vec2::new(100.0, 100.0)).await.ok();
}
```

### Creating and Presenting Content

```rust
use fuchsia_ui_composition::{ContentId, ImageProperties, Vec2, PresentArgs};

async fn create_image_content(
    flatland: &FlatlandProxy,
    width: f32,
    height: f32,
) -> ContentId {
    let content_id = ContentId::new(100);
    
    // Create image content
    let image_props = ImageProperties {
        size: Vec2::new(width, height),
    };
    
    flatland.create_image(
        &content_id,
        // buffer_collection_import_token would come from Allocator
        &buffer_import_token,
        0, // vmo_index
        &image_props,
    ).await.ok();
    
    content_id
}

async fn present_frame(flatland: &FlatlandProxy) {
    let present_args = PresentArgs {
        requested_presentation_time: 0, // present ASAP
        acquire_fences: 0,
        release_fences: 0,
        unsquashable: false,
    };
    
    flatland.present(&present_args).await.ok();
}
```

### Buffer Allocation for Images

```rust
use fuchsia_ui_composition::{AllocatorProxy, AllocatorMarker};
use fuchsia_ui_composition::{
    BufferCollectionExportToken,
    BufferCollectionImportToken,
};

async fn allocate_image_buffer() -> (BufferCollectionExportToken, BufferCollectionImportToken) {
    let (allocator, server_end) = create_proxy::<AllocatorMarker>().unwrap();
    
    // Create token pair for buffer collection
    let (export_token, import_token) = /* create token pair */;
    
    // Register buffer collection with allocator
    allocator.register_buffer_collection(
        &export_token,
        // sysmem_token from fuchsia.sysmem
    ).await.ok();
    
    (export_token, import_token)
}
```

## ZirconWindow Integration

The `ZirconWindow` struct in `src/shell/zircon_window.rs` provides the windowing abstraction for Servo integration.

### Current Implementation

```rust
use fuchsia_ui_composition::FlatlandProxy;
use fuchsia_ui_views::ViewCreationToken;

pub struct ZirconWindow {
    flatland: FlatlandProxy,
    view_creation_token: Option<ViewCreationToken>,
    root_transform: TransformId,
    content_transform: TransformId,
}

impl ZirconWindow {
    pub async fn new() -> Result<Self, Error> {
        // Connect to Flatland
        let flatland = create_flatland_session().await?;
        
        // Set up scene graph
        let root_transform = TransformId::new(1);
        flatland.create_transform(&root_transform).await?;
        flatland.set_root_transform(&root_transform).await?;
        
        let content_transform = TransformId::new(2);
        flatland.create_transform(&content_transform).await?;
        flatland.add_child(&root_transform, &content_transform).await?;
        
        Ok(Self {
            flatland,
            view_creation_token: None,
            root_transform,
            content_transform,
        })
    }
    
    pub async fn present(&self) {
        let present_args = PresentArgs {
            requested_presentation_time: 0,
            acquire_fences: 0,
            release_fences: 0,
            unsquashable: false,
        };
        
        self.flatland.present(&present_args).await.ok();
    }
    
    pub fn update_content(&self, content_id: ContentId) {
        self.flatland.set_content(&self.content_transform, &content_id).await.ok();
    }
}
```

### Servo Integration

To integrate with Servo's compositor:

1. **Implement Windowing Traits**: `ZirconWindow` should implement Servo's `WindowMethods` trait
2. **Present Callback**: Call `window.present()` from Servo's render loop
3. **Buffer Management**: Use Flatland's buffer allocation for Servo's framebuffers
4. **Input Handling**: Bridge Fuchsia input events to Servo's event system

Example flow:

```rust
// Servo render loop
impl WindowMethods for ZirconWindow {
    fn present(&self) {
        // Called by Servo after compositing a frame
        futures::executor::block_on(async {
            self.present().await;
        });
    }
    
    fn create_event_loop_waker(&self) -> Box<dyn EventLoopWaker> {
        // Integrate with Fuchsia async executor
        Box::new(FuchsiaEventLoopWaker::new())
    }
}
```

## View Creation and ViewRef

Views are the fundamental unit of UI in Fuchsia. Each Flatland session represents a view:

```rust
use fuchsia_ui_views::{
    ViewCreationToken, ViewportCreationToken,
    ViewRef, ViewRefControl, ViewIdentityOnCreation,
};

fn create_view_tokens() -> (ViewCreationToken, ViewportCreationToken) {
    // Create event pair for view/viewport link
    let (view_token, viewport_token) = fidl::EventPair::create().unwrap();
    
    (
        ViewCreationToken::new(view_token),
        ViewportCreationToken::new(viewport_token),
    )
}

fn create_view_ref() -> (ViewRef, ViewRefControl) {
    // ViewRef is used for focus and hit testing
    let (view_ref, view_ref_control) = fidl::EventPair::create().unwrap();
    
    (
        ViewRef::new(view_ref),
        ViewRefControl { reference: view_ref_control },
    )
}

async fn create_flatland_view(
    flatland: &FlatlandProxy,
    view_creation_token: ViewCreationToken,
) {
    let (view_ref, view_ref_control) = create_view_ref();
    
    let view_identity = ViewIdentityOnCreation {
        view_ref,
        view_ref_control,
    };
    
    flatland.create_view(
        &view_creation_token,
        &view_identity,
    ).await.ok();
}
```

## Input Handling

Input events from `fuchsia.input` need to be translated to Servo events:

```rust
use fuchsia_input::{KeyEvent, TouchEvent, EventPhase, Key};

fn handle_key_event(key_event: KeyEvent) {
    match key_event.phase {
        EventPhase::Add => {
            // Key pressed
            println!("Key {:?} pressed", key_event.key);
        }
        EventPhase::Remove => {
            // Key released
            println!("Key {:?} released", key_event.key);
        }
        _ => {}
    }
}

fn handle_touch_event(touch_event: TouchEvent) {
    match touch_event.phase {
        EventPhase::Add => {
            println!("Touch down at ({}, {})", touch_event.x, touch_event.y);
        }
        EventPhase::Change => {
            println!("Touch moved to ({}, {})", touch_event.x, touch_event.y);
        }
        EventPhase::Remove => {
            println!("Touch up");
        }
        _ => {}
    }
}
```

## Build Commands

To build with the FIDL bindings:

### GN Build

```bash
# Set up environment
source tools/soliloquy/env.sh

# Build shell
fx build //src/shell:soliloquy_shell
```

### Bazel Build

```bash
bazel build //src/shell:soliloquy_shell
```

### Cargo Build (for development)

```bash
cd src/shell
cargo build
```

## Troubleshooting

### Missing FIDL Tools

**Error**: `fidlc not found at /path/to/sdk/tools/fidlc`

**Solution**: Ensure the Fuchsia SDK is properly installed:
```bash
./tools/soliloquy/setup_sdk.sh
source tools/soliloquy/env.sh
```

### FIDL Compilation Errors

**Error**: `fidlc failed for fuchsia.ui.composition`

**Solution**: This usually means FIDL source files are missing or incompatible. Verify SDK version and re-download if necessary.

### Placeholder Bindings

If you see warnings about placeholder bindings, it means actual FIDL sources weren't found. The script creates minimal stubs to allow the build to proceed. To generate real bindings, install the SDK with FIDL sources.

### Cargo Build Fails with Missing Dependencies

**Error**: `error[E0432]: unresolved import 'fidl'`

**Solution**: The stub `fidl` crate may not be in the right location. Verify that `third_party/fuchsia-sdk-rust/fidl` exists and is included in the workspace.

## Resources

- [Fuchsia Flatland Documentation](https://fuchsia.dev/fuchsia-src/concepts/ui/scenic/flatland)
- [FIDL Language Specification](https://fuchsia.dev/fuchsia-src/reference/fidl/language/language)
- [Fuchsia UI Input](https://fuchsia.dev/fuchsia-src/concepts/ui/input)
- [Scenic Views](https://fuchsia.dev/fuchsia-src/concepts/ui/scenic/views)

## Next Steps

1. **Implement Real Flatland Connection**: Currently `ZirconWindow` is a stub. Connect to the actual Flatland service via component framework.

2. **Buffer Allocation**: Integrate with `fuchsia.sysmem` for shared memory buffer allocation between Servo and the compositor.

3. **Input Pipeline**: Implement full input event routing from Fuchsia input protocols to Servo.

4. **Focus Management**: Handle view focus changes using `ViewRefFocused` protocol.

5. **Testing**: Write integration tests that verify Flatland scene graph operations.

See `docs/servo_integration.md` for more details on Servo-specific integration work.
