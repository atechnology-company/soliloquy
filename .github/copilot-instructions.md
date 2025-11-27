# Soliloquy Copilot Instructions

Soliloquy is a minimal, web-native OS built on **Zircon microkernel** with **Servo browser engine** as the desktop environment. Target hardware: Radxa Cubie A5E (ARM Cortex-A55, Mali-G57 GPU).

## Architecture Overview

```
Soliloquy Shell (Rust) → Servo + V8 → Flatland Compositor → Zircon
     ↓                      ↓
  FIDL protocols     Soliloquy HAL (C++) → Device Drivers
```

### Core Components

- **src/shell/**: Main shell in Rust - `servo_embedder.rs` (Servo integration), `v8_runtime.rs` (JS execution), `zircon_window.rs` (Flatland graphics)
- **drivers/common/soliloquy_hal/**: Hardware abstraction layer (MMIO, SDIO, firmware loading, clock/reset) - used by all device drivers
- **drivers/wifi/aic8800/**: AIC8800D80 WiFi driver (C++ and Rust implementations)
- **gen/fidl/**: Real FIDL protocol implementations (Flatland, Views, Input, WLAN)
- **third_party/zircon_v/**: V language translations of Zircon subsystems (VM, IPC)

### FIDL Protocol Implementations

Full implementations (not stubs) are in `gen/fidl/`:
- `fuchsia_ui_composition/` - Flatland compositor with scene graph, transforms, content
- `fuchsia_ui_views/` - View tree, viewports, focus management
- `fuchsia_ui_input/` - Keyboard, touch, and mouse input handling
- `fuchsia_wlan_softmac/` - WLAN MAC layer for WiFi drivers

## Build System

**Primary build**: Bazel with Bzlmod (`MODULE.bazel`)
```bash
bazel build //src/shell:soliloquy_shell_simple  # Quick test build
bazel build //...                                # Build all targets
bazel test //...                                 # Run all tests
```

**Full Fuchsia build** (Linux only):
```bash
./tools/soliloquy/setup.sh      # One-time bootstrap
./tools/soliloquy/build.sh      # Build with fx
```

**SDK-only build** (cross-platform):
```bash
./tools/soliloquy/setup_sdk.sh  # Download Fuchsia SDK
./tools/soliloquy/build_sdk.sh  # Build with SDK
```

## Code Patterns

### Rust Components
- Use `log::{info, error, debug, warn}` for logging (connects to `fuchsia.logger.LogSink`)
- State machine pattern for lifecycle management (see `EmbedderState` in `servo_embedder.rs`)
- Feature flags for conditional Fuchsia code: `#[cfg(feature = "fuchsia")]`
- FIDL protocol usage declared in component manifests (`meta/*.cml`)

### C++ Drivers
- All drivers depend on `//drivers/common/soliloquy_hal` for hardware access
- Use DDK types: `ddk::MmioBuffer`, `ddk::SdioProtocolClient`
- Follow `drivers/gpio/soliloquy_gpio/` as reference implementation

### Component Manifests (CML)
Location: `src/*/meta/*.cml` - declare capabilities in `use:` block:
```json
use: [
    { protocol: ["fuchsia.ui.composition.Flatland", "fuchsia.ui.input3.Keyboard"] },
    { storage: "data", path: "/data" },
]
```

## C-to-V Translation

Zircon kernel subsystems translated from C/C++ to idiomatic V language:

### Translated Subsystems

**VM (Virtual Memory)**:
- `third_party/zircon_v/vm/vm_types.v` - Core types (PAddr, VAddr, VmPage, ZxStatus)
- `third_party/zircon_v/vm/pmm_arena_v2.v` - Physical Memory Manager with bitmap allocator
- `third_party/zircon_v/vm/vmo.v` - Virtual Memory Objects with demand paging
- `third_party/zircon_v/vm/page_fault_handler.v` - Page fault handling and prefaulting

**IPC (Inter-Process Communication)**:
- `third_party/zircon_v/ipc/ipc_types.v` - Core IPC types (handles, rights, signals, status codes)
- `third_party/zircon_v/ipc/channel_v2.v` - Bidirectional message channels with handle transfer
- `third_party/zircon_v/ipc/port.v` - Async event ports for I/O multiplexing

### V Code Style

```v
// Module declaration at top
module vm

// Use V's enum for status codes
pub enum ZxStatus {
    ok = 0
    err_no_memory = -4
    err_peer_closed = -24
}

// Struct methods use receiver syntax
pub fn (mut arena PmmArena) alloc_page() ?&VmPage {
    // Use sync.Mutex for thread safety
    arena.lock.@lock()
    defer { arena.lock.unlock() }
    // ...
}

// Tests are inline functions prefixed with test_
fn test_arena_alloc() {
    mut arena := PmmArena.new(0x1000, 64)
    page := arena.alloc_page() or { panic('alloc failed') }
    assert page.state == .free
}
```

### Translation Guidelines

1. Prefer V idioms over direct C translation
2. Use `sync.Mutex` for thread safety (not raw atomics)
3. Include unit tests in same file (V convention)
4. Use `?T` for optional/error returns instead of null pointers
5. Original C sources in `third_party/zircon_c/<subsystem>/`
6. Build rules: `build/v_rules.bzl` (Bazel), `build/v_rules.gni` (GN)

## Testing

```bash
./tools/soliloquy/test.sh              # All tests
./tools/soliloquy/test.sh --coverage   # With coverage
bazel test //src/shell:soliloquy_shell_tests  # Shell tests only
```

- Test support crate: `test/support/` with mock FIDL servers (MockFlatland, MockTouchSource)
- Integration test manifests: `test/components/*.cml`
- Driver tests: `drivers/*/tests/` (C++ with Google Test)

## Device Drivers

### WiFi Driver (AIC8800D80)

**Rust Implementation** (`drivers/wifi/aic8800/aic8800_rust/`):
```rust
// Create driver with SDIO interface
let mut driver = Aic8800Driver::new(sdio);
driver.init()?;  // Downloads firmware, configures chip

// Transmit data
driver.transmit(&packet_data)?;

// Set channel
driver.set_channel(&Channel::CHANNELS_2GHZ[5])?;  // Channel 6
```

**Key Components**:
- `SdioInterface` trait for hardware abstraction
- `TxQueue`/`RxBuffer` for packet management
- `FirmwareLoader` for loading `fmacfw_8800d80.bin`
- `WlanSoftmacBridge` in `gen/fidl/fuchsia_wlan_softmac/` for MAC layer

**Linux Driver Source**: `vendor/aic8800-linux/drivers/aic8800/` (reference for porting)

### Driver Development Pattern

1. Read Linux driver to understand hardware protocol
2. Create Rust implementation using `SdioInterface` trait
3. Implement WLAN SoftMAC bridge for Fuchsia networking stack
4. Use HAL (`drivers/common/soliloquy_hal/`) for low-level access

## Key Scripts

| Script | Purpose |
|--------|---------|
| `tools/soliloquy/setup_sdk.sh` | Download Fuchsia SDK |
| `tools/soliloquy/build_bazel.sh` | Bazel component build |
| `tools/soliloquy/validate_manifest.sh` | Validate CML files |
| `tools/soliloquy/flash.sh` | Flash to device |
| `tools/soliloquy/c2v_pipeline.sh` | C-to-V translation |

## Commit Message Format

```
<type>(<scope>): <subject>

Types: feat, fix, docs, test, refactor, chore
Example: feat(wifi): add AIC8800 firmware loading
```
