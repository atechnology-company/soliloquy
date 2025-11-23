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
export PATH="$HOME/.local/bin:$PATH"
bazel build //src/shell:soliloquy_shell_simple
```

4. **Run test:**
```bash
./bazel-bin/src/shell/soliloquy_shell_simple
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

- `tools/soliloquy/setup_sdk.sh` - Download and configure SDK
- `tools/soliloquy/build_bazel.sh` - Build with Bazel
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