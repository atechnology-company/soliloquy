# Soliloquy OS Developer Guide

## 1. Project Vision
**Soliloquy** is a minimal, web-native operating system built on the **Zircon microkernel**. It aims to be what ChromeOS could have been: a pure web runtime without legacy baggage.

- **Kernel**: Zircon (Fuchsia's microkernel)
- **Userland**: Minimal drivers + Servo Browser Engine
- **UI**: Svelte-based Web UI (Plates)
- **Target Hardware**: Radxa Cubie A5E (Allwinner A527, ARM64)

## 2. Architecture Stack
The system is layered as follows:

1.  **Hardware**: Allwinner A527 (ARM64)
2.  **Kernel**: Zircon (handles scheduling, memory, IPC)
3.  **Drivers (DDK)**:
    -   Written in C++ (mostly) or Rust.
    -   Key drivers: UART, eMMC, Ethernet, AIC8800 WiFi, Mali GPU.
4.  **System Services**: Minimal services for network and graphics (Magma).
5.  **Runtime**: **Servo** (Rust-based browser engine).
    -   **JS Engine**: `rusty_v8` (V8 bindings for Rust).
    -   **Rendering**: WebRender (GPU accelerated).
6.  **Application**: The "Shell" is just a web page running in Servo.

## 3. Development Environment

### Primary Build System
- **OS**: Linux (Fedora/Debian/Ubuntu). macOS is supported for editing but building requires Linux (or a VM/Container).
- **Build Tools**: `gn` (Generate Ninja) and `ninja`.
- **Language Toolchains**:
    -   **Rust**: Stable, with `aarch64-unknown-fuchsia` target.
    -   **C++**: Clang/LLVM (provided by Fuchsia tree).
    -   **Python**: 3.8+ for build scripts.

### Directory Structure
```
//
├── boards/               # Board definitions
│   └── arm64/soliloquy/  # Radxa Cubie A5E config
├── drivers/              # Custom drivers
│   └── wifi/aic8800/     # Ported WiFi driver
├── tools/soliloquy/      # Helper scripts (build, setup, flash)
├── vendor/               # Third-party deps (Servo, etc.)
└── ... (Standard Fuchsia tree)
```

## 4. Workflows for AI Agents & Developers

### Setting Up
1.  **Bootstrap**: Run `tools/soliloquy/setup.sh`. It handles dependencies and Fuchsia cloning.
2.  **Environment**: Always `source scripts/fx-env.sh` before running `fx` commands.

### Building
Use the helper script:
```bash
./tools/soliloquy/build.sh
```
Or manually:
```bash
fx set minimal.arm64 --board soliloquy
fx build
```

### Remote Building (Fedora via SSH)
If you are on macOS and using the Fedora instance (`undivisible@fedora@orb`):
1.  Sync code to the remote instance.
2.  Run build commands via SSH.
3.  (Optional) Use `tools/soliloquy/ssh_build.sh` (if available).

### Adding a Driver
1.  Create directory in `drivers/<category>/<name>`.
2.  Create `BUILD.gn` defining `driver_module`.
3.  Implement `bind` hooks and DDK lifecycle methods.
4.  Add to `boards/arm64/soliloquy/board_config.gni` under `board_driver_package_labels`.

## 5. Current Status & Roadmap
- [x] **Board Config**: Basic GN files for Soliloquy board created.
- [x] **WiFi Driver**: Skeleton for AIC8800D80 created.
- [ ] **Servo Integration**: Needs platform abstraction layer for Zircon.
- [ ] **GPU Driver**: Mali-G57 integration needed (Magma).

## 6. Key Constraints
- **No POSIX**: Do not assume standard libc/POSIX availability in kernel/driver space.
- **Async First**: Use Zircon's async loop and FIDL for IPC.
- **Web Only**: No terminal apps, no X11/Wayland. The "display" is a full-screen browser.
