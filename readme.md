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
├── ui/
│   └── tauri-shell/        # UI Prototype (Tauri + Svelte)
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
- `tools/soliloquy/validate_manifest.sh` - Validate component manifests
- `tools/soliloquy/flash.sh` - Flash to device (fastboot)
- `tools/soliloquy/debug.sh` - Serial console debugging
- `tools/soliloquy/dev_ui.sh` - Start UI prototype development server

### UI Development

The Soliloquy shell UI is prototyped using Tauri + Svelte for rapid development and design iteration:

```bash
# Start the UI development server
./tools/soliloquy/dev_ui.sh

# Or manually:
cd ui/tauri-shell && npm install && npm run tauri:dev
```

**UI Stack:**
- **Prototype**: Tauri + Svelte (for development)
- **Production**: Servo + WebRender + V8 (in the actual OS)
- **Design**: Svelte-based web UI (Plates vision)

The UI prototype demonstrates:
- Desktop shell interface with status bar and launcher
- Web application rendering area (placeholder for Servo)
- System integration patterns for the web-native OS

### When to Use the UI Scaffold

**Use the Tauri UI prototype when:**

1. **UI/UX Design Phase**: Prototype and iterate on the desktop interface before implementing in Servo
2. **Component Development**: Build and test individual UI components in isolation
3. **User Testing**: Gather feedback on the desktop experience and interaction patterns
4. **Design Reviews**: Generate screenshots and demos for stakeholders
5. **Integration Testing**: Test web application compatibility with the shell interface

**Development Workflow:**
```bash
# Quick development iteration
./tools/soliloquy/dev_ui.sh

# Build for screenshots/demos
./tools/soliloquy/build_ui.sh

# Serve built files for review
cd ui/tauri-shell && npx serve build -p 3000
```

**Integration Path to Production:**
1. **Phase 1**: Tauri prototype (current) - Design validation and user testing
2. **Phase 2**: Port components to run in Servo browser engine
3. **Phase 3**: Integration with Zircon system services and FIDL
4. **Phase 4**: Full production deployment on Soliloquy OS with Servo runtime

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

- [Build System Guide](docs/build.md)
- [Component Manifest Guide](docs/component_manifest.md)
- [Servo Integration](docs/servo_integration.md)
- [Developer Guide](DEVELOPER_GUIDE.md)
- [Testing Guide](docs/testing.md)
- [Servo Integration](docs/servo_integration.md)
- [Implementation Plan](docs/implementation_plan.md)
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