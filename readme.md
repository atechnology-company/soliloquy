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
- 🔄 Servo browser engine integration ✅ **V8 Runtime Integrated**
- 🔄 WiFi driver porting (AIC8800D80)
- 🔄 Component development

## Quick Start

### Prerequisites

**For macOS:**
- macOS 10.15 or later
- Homebrew (install from https://brew.sh)
- 10GB+ free disk space

**For Linux:**
- Fedora, RHEL, Debian, or Ubuntu
- 10GB+ free disk space (20GB+ recommended for full source build)

### Setup on macOS (SDK-Only - Recommended)

1. **Clone repository:**
```bash
git clone https://github.com/yourusername/soliloquy.git
cd soliloquy
```

2. **Install Homebrew (if not already installed):**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. **Download Fuchsia SDK:**
```bash
./tools/soliloquy/setup_sdk.sh
```

4. **Set up environment:**
```bash
source tools/soliloquy/env.sh
```

5. **Build (Bazel-based):**
```bash
export PATH="$HOME/.local/bin:$PATH"
bazel build //src/shell:soliloquy_shell_simple
```

### Setup on Linux (Full Source Build - Advanced)

For full Fuchsia source tree development on Linux:

1. **Clone repository:**
```bash
git clone https://github.com/yourusername/soliloquy.git
cd soliloquy
```

2. **Bootstrap Fuchsia:**
```bash
./tools/soliloquy/setup.sh
```
This will:
- Install all dependencies (git, build tools, Python, etc.)
- Clone the Fuchsia repository
- Bootstrap the build system
- Link Soliloquy sources into the Fuchsia tree

3. **Build using fx:**
```bash
source fuchsia/fuchsia/scripts/fx-env.sh
fx set minimal.arm64 --board soliloquy
fx build
```

### SDK Version Pinning

To use a specific SDK version (default is "latest"):
```bash
export FUCHSIA_SDK_VERSION=20231115.2
./tools/soliloquy/setup_sdk.sh
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

- `tools/soliloquy/setup_sdk.sh` - Download and configure SDK
- `tools/soliloquy/build_bazel.sh` - Build with Bazel
- `tools/soliloquy/flash.sh` - Flash to device (fastboot)
- `tools/soliloquy/debug.sh` - Serial console debugging

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
- [Servo Integration](docs/servo_integration.md) ✅ **New**
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