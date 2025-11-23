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

Soliloquy provides a Hardware Abstraction Layer (HAL) in `drivers/common/soliloquy_hal` that simplifies common driver tasks. All new drivers should use this HAL.

#### HAL Components

The `soliloquy_hal` library provides:

- **Firmware Loading** (`firmware.h`): Load and map firmware files
- **SDIO Helpers** (`sdio.h`): Simplified SDIO transaction helpers and firmware download
- **MMIO Access** (`mmio.h`): Register read/write with bit manipulation utilities
- **Clock/Reset Control** (`clock_reset.h`): Enable/disable clocks and manage resets

#### Creating a New Driver

1.  **Create directory**: `drivers/<category>/<name>/`

2.  **Implement driver class**:
    ```cpp
    #include "../../common/soliloquy_hal/firmware.h"
    #include "../../common/soliloquy_hal/mmio.h"
    // etc.

    class MyDriver : public ddk::Device<MyDriver> {
      // Use HAL helpers
      std::unique_ptr<soliloquy_hal::MmioHelper> mmio_helper_;
    };
    ```

3.  **Create `BUILD.gn`**:
    ```gn
    driver_module("my_driver") {
      sources = [ "my_driver.cc", "my_driver.h" ]
      deps = [
        "//drivers/common/soliloquy_hal",  # Include HAL
        "//src/lib/ddk",
        # ... other deps
      ]
    }
    ```

4.  **Register board device** in `boards/arm64/soliloquy/src/soliloquy-<device>.cc`:
    - Define MMIO/IRQ resources using `pbus_mmio_t`, `pbus_irq_t`
    - Call `pbus_.DeviceAdd()` in init function
    - Add init call to `Soliloquy::Start()` in `soliloquy.cc`

5.  **Add to board config**: Edit `boards/arm64/soliloquy/board_config.gni`:
    ```gn
    board_driver_package_labels = [
      "//drivers/<category>/<name>:<target>",
    ]
    ```

#### Example: GPIO Driver

See `drivers/gpio/soliloquy_gpio/` for a reference implementation that uses the HAL for MMIO access.

#### Example: WiFi Driver (AIC8800)

The AIC8800 driver (`drivers/wifi/aic8800/`) demonstrates HAL usage for:
- Firmware loading with `FirmwareLoader::LoadFirmware()`
- SDIO transactions with `SdioHelper`
- Firmware download to hardware

## 5. Current Status & Roadmap
- [x] **Board Config**: Basic GN files for Soliloquy board created.
- [x] **Driver HAL**: Common hardware abstraction layer (`drivers/common/soliloquy_hal`) for MMIO, SDIO, firmware loading, and clock/reset control.
- [x] **WiFi Driver**: AIC8800D80 driver refactored to use HAL.
- [x] **GPIO Driver**: Generic GPIO driver using HAL as reference implementation.
- [ ] **Servo Integration**: Needs platform abstraction layer for Zircon.
- [ ] **GPU Driver**: Mali-G57 integration needed (Magma).

## 6. Key Constraints
- **No POSIX**: Do not assume standard libc/POSIX availability in kernel/driver space.
- **Async First**: Use Zircon's async loop and FIDL for IPC.
- **Web Only**: No terminal apps, no X11/Wayland. The "display" is a full-screen browser.
