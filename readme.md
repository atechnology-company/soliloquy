# Soliloquy OS

A minimal, web-native operating system built on the Zircon microkernel with Servo as the desktop environment.

## Overview

Soliloquy is an experimental OS that brings web technologies to the system level. It uses:
- **Zircon** - Microkernel from Fuchsia
- **Servo** - Modern browser engine for UI
- **V8** - JavaScript runtime
- **WGPU** - Graphics via Vulkan

## Target Hardware

**Radxa Cubie A5E**
- SoC: Allwinner A527 (ARM Cortex-A55)
- RAM: 8GB LPDDR4
- Storage: eMMC + microSD
- WiFi: AIC8800D80
- GPU: Mali-G57

## Project Status

🚧 **Early Development** - Build system functional, component development in progress

**Completed:**
- ✅ Fuchsia SDK integration (2.3GB)
- ✅ Bazel build system configured
- ✅ First component builds successfully
- ✅ Development workflow scripts
- ✅ SDK library wrappers

**In Progress:**
- 🔄 Servo browser engine integration
- 🔄 WiFi driver porting (AIC8800D80)
- 🔄 Component development

## Quick Start

### Prerequisites
- macOS or Linux
- Bazel (installed via Bazelisk)
- 10GB+ free disk space

### Setup

1. **Clone repository:**
```bash
git clone https://github.com/yourusername/soliloquy.git
cd soliloquy
```

2. **Download Fuchsia SDK:**
```bash
./tools/soliloquy/setup_sdk.sh
```

3. **Build:**
   ```bash
   # For macOS users with Linux server:
   ./tools/soliloquy/ssh_build.sh user@linux-server
   
   # For Linux users (full build):
   ./tools/soliloquy/setup.sh  # One-time setup
   ./tools/soliloquy/build.sh
   
   # For cross-platform component development:
   ./tools/soliloquy/setup_sdk.sh
   ./tools/soliloquy/build_sdk.sh
   ```

   📖 **See [Build System Guide](docs/build.md)** for detailed build options and platform-specific instructions.

4. **Run test:**
```bash
./bazel-bin/src/shell/soliloquy_shell_simple
```

## Project Structure

```
soliloquy/
├── src/
│   └── shell/              # Soliloquy Shell (Rust)
├── drivers/
│   └── wifi/aic8800/       # WiFi driver (C++)
├── boards/
│   └── arm64/soliloquy/    # Board configuration
├── vendor/
│   └── servo/              # Servo browser engine
├── sdk/                    # Fuchsia SDK (downloaded)
├── tools/soliloquy/        # Build & development scripts
└── BUILD.bazel             # Root build file
```

## Development

### Build System

Uses Bazel with Bzlmod (MODULE.bazel):
- `bazel build //...` - Build all targets
- `bazel build //src/shell:soliloquy_shell_simple` - Build shell
- `bazel build //sdk:libs` - Build SDK libraries

### Scripts

- `tools/soliloquy/setup.sh` - Bootstrap full Fuchsia checkout (Linux)
- `tools/soliloquy/setup_sdk.sh` - Download and configure SDK
- `tools/soliloquy/build.sh` - Full Fuchsia build with Soliloquy (Linux)
- `tools/soliloquy/ssh_build.sh` - Remote build from macOS to Linux
- `tools/soliloquy/build_sdk.sh` - SDK-based cross-platform build
- `tools/soliloquy/build_bazel.sh` - Bazel component build
- `tools/soliloquy/flash.sh` - Flash to device (fastboot)
- `tools/soliloquy/debug.sh` - Serial console debugging

All build scripts support `--help` for detailed usage information.

## Architecture

### Component Stack
```
┌─────────────────────────────────┐
│    Soliloquy Shell (Rust)       │
│  ┌──────────┐   ┌────────────┐  │
│  │  Servo   │   │ V8 Runtime │  │
│  └────┬─────┘   └────────────┘  │
│       │ WebRender/WGPU           │
│       ▼                          │
│  ┌──────────────────────────┐   │
│  │  Flatland (Compositor)   │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│   Zircon Microkernel            │
└─────────────────────────────────┘
```

### Desktop Environment

Servo runs as a Fuchsia component, providing:
- Window management via Flatland
- Web-based UI rendering
- JavaScript execution (V8)
- Hardware-accelerated graphics (Vulkan/Mali)

## Contributing

This is an experimental project. Contributions welcome!

### Development Workflow

1. Create feature branch
2. Make changes
3. Test with `bazel build //...`
4. Submit PR

## Documentation

- [Implementation Plan](docs/implementation_plan.md)
- [Servo Integration](docs/servo_integration.md)
- [Development Walkthrough](docs/walkthrough.md)

## License

BSD-3-Clause (see LICENSE file)

## Acknowledgments

- Fuchsia Project - Zircon microkernel
- Servo Project - Browser engine
- V8 Project - JavaScript runtime
- Radxa - Hardware platform

---

**Note:** This is an experimental OS project. Not intended for production use.