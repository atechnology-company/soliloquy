# Soliloquy Build Manager

A next-generation build management system for Soliloquy OS with both GUI and CLI interfaces.

## Features

### 🚀 Core Features
- **Multi-Build System Support**: Unified interface for GN, Bazel, and Cargo
- **Real-time Monitoring**: Live build output streaming with progress tracking
- **Intelligent Module Management**: Visual dependency graphs and impact analysis
- **Build Profiles**: Save and share common build configurations
- **Smart Caching**: Intelligent cache management and statistics

### 📊 Build Analytics
- Performance metrics and build time trends
- Resource usage monitoring (CPU, memory, disk)
- Build history and comparison
- Success/failure rate tracking
- Bottleneck identification

### 🧪 Test Management
- Run tests by category (unit, integration, system)
- Real-time test results and coverage
- Test history and trend analysis
- Parallel test execution
- Flaky test detection

### 🔧 Development Tools
- One-click environment setup
- FIDL binding generation UI
- C-to-V translation manager
- VM subsystem integration dashboard
- SDK version management

### 🎯 Smart Features
- **Error Intelligence**: Parse build errors and suggest fixes
- **Dependency Inspector**: Interactive dependency graph visualization
- **Build Comparison**: Before/after analysis for code changes
- **Translation Dashboard**: Track C-to-V translation progress
- **Quick Actions**: Keyboard shortcuts for common workflows

### 🌐 Cross-Platform
- Linux and macOS support
- Architecture detection (x86_64, arm64)
- Remote build support
- Build scheduling and queuing

## Components

### GUI Application (`build_manager_gui/`)
Tauri-based desktop application with React + TypeScript frontend.

**Key Views:**
- Dashboard: Overall project health and quick actions
- Build Manager: Start, monitor, and control builds
- Module Browser: Navigate and manage project modules
- Output Viewer: Advanced log viewing with filtering
- Test Runner: Comprehensive test management
- Analytics: Build metrics and trends
- Settings: Configuration and preferences

### CLI Tool (`build_manager_cli/`)
Command-line interface for CI/CD and automation.

**Commands:**
```bash
# Build management
soliloquy-build start [target] --system [gn|bazel|cargo]
soliloquy-build stop [build-id]
soliloquy-build status
soliloquy-build clean

# Module operations
soliloquy-build module list
soliloquy-build module info <name>
soliloquy-build module deps <name>
soliloquy-build module build <name>

# Testing
soliloquy-build test run [pattern]
soliloquy-build test list
soliloquy-build test report

# Development tools
soliloquy-build fidl generate [library]
soliloquy-build c2v translate <subsystem>
soliloquy-build env setup
soliloquy-build env check

# Analytics
soliloquy-build stats
soliloquy-build history [days]
soliloquy-build compare <build-id-1> <build-id-2>

# Profiles
soliloquy-build profile save <name>
soliloquy-build profile load <name>
soliloquy-build profile list
```

### Core Library (`build_core/`)
Shared Rust library used by both GUI and CLI.

**Modules:**
- `build_systems/`: Interfaces for GN, Bazel, Cargo
- `module_manager/`: Module discovery and dependency tracking
- `build_executor/`: Build execution and monitoring
- `test_runner/`: Test execution and reporting
- `analytics/`: Metrics collection and analysis
- `config/`: Configuration management
- `database/`: SQLite-based build history

## Installation

### Prerequisites
```bash
# Install Rust and Node.js
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# Node.js 18+ required for Tauri

# Install system dependencies
# Linux
sudo apt-get install -y libwebkit2gtk-4.0-dev build-essential curl wget \
  libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev

# macOS
brew install webkit2gtk
```

### Build from Source

```bash
# Build core library
cd tools/build_manager/build_core
cargo build --release

# Build CLI
cd ../build_manager_cli
cargo build --release
cargo install --path .

# Build GUI
cd ../build_manager_gui
npm install
npm run tauri build
```

### Install Pre-built Binaries
```bash
# Download latest release
./tools/build_manager/install.sh
```

## Quick Start

### GUI Application
```bash
# Launch the GUI
soliloquy-build-manager

# Or from source
cd tools/build_manager/build_manager_gui
npm run tauri dev
```

### CLI Tool
```bash
# Check environment
soliloquy-build env check

# Start a build
soliloquy-build start //src/shell:soliloquy_shell --system bazel

# Monitor build
soliloquy-build status --follow

# Run tests
soliloquy-build test run //test/vm:tests
```

## Configuration

Configuration file: `~/.config/soliloquy-build/config.toml`

```toml
[general]
project_root = "/path/to/soliloquy"
default_build_system = "bazel"
parallel_jobs = 8

[build_systems]
gn_path = "gn"
ninja_path = "ninja"
bazel_path = "bazel"
cargo_path = "cargo"

[cache]
enabled = true
max_size_gb = 50
clean_threshold_days = 30

[notifications]
enabled = true
on_success = true
on_failure = true

[ui]
theme = "dark"
font_size = 14
```

## Architecture

```
┌─────────────────────────────────────────┐
│         GUI (Tauri + React)             │
│  ┌──────────┬──────────┬──────────┐    │
│  │Dashboard │ Modules  │  Tests   │    │
│  └──────────┴──────────┴──────────┘    │
└─────────────────┬───────────────────────┘
                  │ IPC
┌─────────────────▼───────────────────────┐
│            Build Core Library            │
│  ┌──────────────────────────────────┐  │
│  │    Build System Abstraction      │  │
│  ├──────────┬──────────┬────────────┤  │
│  │    GN    │  Bazel   │   Cargo    │  │
│  └──────────┴──────────┴────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │   Module & Dependency Manager    │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │      Build Executor & Monitor    │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │    Analytics & History (SQLite)  │  │
│  └──────────────────────────────────┘  │
└─────────────────┬───────────────────────┘
                  │ Direct API
┌─────────────────▼───────────────────────┐
│         CLI Tool (clap-based)           │
└─────────────────────────────────────────┘
```

## Development

### Running Tests
```bash
# Core library tests
cd build_core
cargo test

# CLI tests
cd ../build_manager_cli
cargo test

# GUI tests
cd ../build_manager_gui
npm test
```

### Code Structure
```
tools/build_manager/
├── build_core/              # Shared Rust library
│   ├── src/
│   │   ├── lib.rs
│   │   ├── build_systems/  # GN, Bazel, Cargo interfaces
│   │   ├── module_manager/ # Module discovery
│   │   ├── executor/       # Build execution
│   │   ├── analytics/      # Metrics and history
│   │   └── config/         # Configuration
│   └── Cargo.toml
├── build_manager_cli/       # CLI tool
│   ├── src/
│   │   ├── main.rs
│   │   └── commands/       # CLI commands
│   └── Cargo.toml
└── build_manager_gui/       # Tauri GUI app
    ├── src-tauri/          # Rust backend
    │   ├── src/
    │   │   ├── main.rs
    │   │   └── commands/   # Tauri commands
    │   └── Cargo.toml
    └── src/                # React frontend
        ├── components/
        ├── views/
        └── services/
```

## Contributing

See the main project DEVELOPER_GUIDE.md for contribution guidelines.

## License

Same as Soliloquy OS project.
