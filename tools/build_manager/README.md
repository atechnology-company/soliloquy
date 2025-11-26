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

## Integration with Soliloquy Tools

The Build Manager integrates with and extends Soliloquy's existing tooling infrastructure:

### Tool Integration

#### Build Scripts (`tools/soliloquy/`)
The Build Manager provides a unified interface to existing build scripts:

```bash
# Traditional approach
./tools/soliloquy/build_sdk.sh
./tools/soliloquy/build_bazel.sh //src/shell:soliloquy_shell

# Build Manager approach
soliloquy-build start //src/shell:soliloquy_shell --system bazel
```

**Integrated Scripts**:
- `build.sh` - Full Fuchsia build
- `build_sdk.sh` - SDK-based build
- `build_bazel.sh` - Bazel component build
- `build_ui.sh` - UI prototype build
- `ssh_build.sh` - Remote build

#### Verification Scripts (`tools/scripts/`)
Run verification scripts directly from Build Manager:

```bash
# Via CLI
soliloquy-build verify c2v-setup
soliloquy-build verify hal-translation
soliloquy-build verify test-framework

# Via GUI
Dashboard → Quick Actions → Verification Tools
```

**Verification Tools**:
- `verify_c2v_setup.sh` - C2V tooling verification
- `verify_hal_v_translation.sh` - HAL translation checks
- `verify_ipc_build.sh` - IPC build verification
- `verify_test_framework.sh` - Test infrastructure checks
- `verify_vm_translation.sh` - VM translation verification

#### Development Tools
Access all Soliloquy development tools through Build Manager:

```bash
# FIDL binding generation
soliloquy-build fidl generate fuchsia.ui.composition
# Wraps: tools/soliloquy/gen_fidl_bindings.sh

# C2V translation
soliloquy-build c2v translate hal
# Wraps: tools/soliloquy/c2v_pipeline.sh --subsystem hal

# Component manifest validation
soliloquy-build validate manifest src/shell/meta/soliloquy_shell.cml
# Wraps: tools/soliloquy/validate_manifest.sh

# Environment setup
soliloquy-build env setup
# Wraps: tools/soliloquy/setup_sdk.sh + env.sh
```

### Tool Discovery

Build Manager automatically discovers and integrates tools:

```bash
# List available tools
soliloquy-build tools list

# Get tool info
soliloquy-build tools info c2v_pipeline

# Run tool directly
soliloquy-build tools run c2v_pipeline --subsystem vm --dry-run
```

### GUI Tool Integration

The Build Manager GUI provides visual interfaces for all tools:

#### Tools Panel
- **Build Scripts**: One-click execution with parameter forms
- **Verification**: Batch verification with visual results
- **C2V Pipeline**: Interactive translation workflow
- **FIDL Generator**: Library browser and generation UI

#### Dashboard Quick Actions
- ▶️ Quick Build (common targets)
- 🔍 Verify Setup (run all verification scripts)
- 🔄 Update SDK (re-run setup_sdk.sh)
- 🧪 Run Tests (test.sh wrapper)

#### Tool Output Viewer
- Real-time streaming output
- Log filtering and search
- Error highlighting
- Copy/export functionality

### Configuration

Configure tool integration in `~/.config/soliloquy-build/config.toml`:

```toml
[tools]
# Tool paths (auto-detected if not specified)
soliloquy_tools_dir = "tools/soliloquy"
verification_scripts_dir = "tools/scripts"

# Tool execution
auto_verify_after_setup = true
save_tool_output = true
output_log_dir = "~/.cache/soliloquy-build/logs"

# GUI integration
show_tools_panel = true
enable_quick_actions = true

[build_wrapper]
# Wrap existing build scripts
use_build_manager_for_scripts = false  # Set true to intercept script calls
log_all_builds = true
```

### Creating Tool Wrappers

Extend Build Manager to wrap custom tools:

```rust
// In build_core/src/tools/mod.rs

pub struct ToolWrapper {
    pub name: String,
    pub script_path: PathBuf,
    pub description: String,
    pub parameters: Vec<ToolParameter>,
}

impl ToolWrapper {
    pub fn execute(&self, params: &HashMap<String, String>) -> Result<Output> {
        // Execute tool script
        let mut cmd = Command::new(&self.script_path);
        
        for (key, value) in params {
            cmd.arg(format!("--{}", key));
            cmd.arg(value);
        }
        
        cmd.output()
    }
}
```

### CLI Tool Commands

Extended CLI commands for tool integration:

```bash
# Verification commands
soliloquy-build verify all               # Run all verification scripts
soliloquy-build verify c2v-setup         # Specific verification
soliloquy-build verify report            # Generate verification report

# Tool execution
soliloquy-build tools exec <tool> [args] # Execute any tool
soliloquy-build tools discover           # Discover available tools
soliloquy-build tools config <tool>      # Configure tool defaults

# Workflow automation
soliloquy-build workflow create <name>   # Create tool workflow
soliloquy-build workflow run <name>      # Run predefined workflow
soliloquy-build workflow list            # List workflows

# Example workflows:
# - setup: setup_sdk.sh → verify_test_framework.sh
# - translate: c2v_pipeline.sh → verify_hal_v_translation.sh
# - release: build_bazel.sh → test.sh → build_ui.sh
```

### Advanced Tool Features

#### Tool Chains
Execute multiple tools in sequence:

```bash
soliloquy-build chain \
  "c2v translate hal" \
  "verify hal-translation" \
  "build //third_party/zircon_v/hal:hal"
```

#### Parallel Tool Execution
Run independent tools in parallel:

```bash
soliloquy-build parallel \
  "verify c2v-setup" \
  "verify hal-translation" \
  "verify vm-translation"
```

#### Tool Scheduling
Schedule tool execution:

```bash
# Run verification nightly
soliloquy-build schedule \
  --cron "0 2 * * *" \
  --command "verify all" \
  --name "nightly-verification"
```

### Tool Development

Adding new tools to Build Manager integration:

1. **Create tool script** in `tools/soliloquy/` or `tools/scripts/`
2. **Add metadata file** (optional): `tool_name.toml`
   ```toml
   [tool]
   name = "my_tool"
   description = "Custom build tool"
   category = "build"
   
   [[parameters]]
   name = "input"
   type = "file"
   required = true
   
   [[parameters]]
   name = "output"
   type = "directory"
   required = false
   default = "out/"
   ```
3. **Build Manager auto-discovers** on next launch
4. **Use via GUI or CLI** immediately

### Performance Monitoring

Build Manager tracks tool execution metrics:

```bash
# View tool statistics
soliloquy-build tools stats

# Output:
# Tool                    Runs    Avg Time    Success Rate
# build_bazel.sh         142     45s         98.5%
# verify_c2v_setup.sh     28     12s         100%
# c2v_pipeline.sh         15     5m 23s      93.3%
```

### Tool Dependencies

Build Manager handles tool dependencies automatically:

```yaml
# tools/build_manager/tool_deps.yaml
c2v_pipeline:
  requires:
    - v_compiler
    - python3
  setup: setup_sdk.sh
  
build_bazel:
  requires:
    - bazel
    - fuchsia_sdk
  setup: setup_sdk.sh
```

---

## Contributing

See the main project [Contributing Guide](../../docs/contibuting.md) for contribution guidelines.

### Build Manager Development

For Build Manager-specific development:

1. **Core Library**: `build_core/` - Rust library
2. **CLI Tool**: `build_manager_cli/` - Command-line interface
3. **GUI App**: `build_manager_gui/` - Tauri application

Run tests:
```bash
cd tools/build_manager
cargo test --all
```

---

## License

Same as Soliloquy OS project.

---

## See Also

- **[Tools Reference](../../docs/guides/tools_reference.md)** - Complete tool documentation
- **[Developer Guide](../../docs/guides/dev_guide.md)** - Development workflow
- **[Build Guide](../../docs/build.md)** - Build system details
