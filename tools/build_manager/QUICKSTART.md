# Soliloquy Build Manager - Quick Start Guide

## Installation

### Quick Install (Recommended)

```bash
cd tools/build_manager
./install.sh
```

This will:
1. Build the core library
2. Build and install the CLI tool
3. Provide instructions for the GUI

### Manual Installation

#### CLI Tool

```bash
# Build core library
cd tools/build_manager/build_core
cargo build --release

# Install CLI
cd ../build_manager_cli
cargo install --path .

# Verify installation
soliloquy-build --version
```

#### GUI Application

```bash
cd tools/build_manager/build_manager_gui

# Install dependencies
npm install

# Development mode
npm run tauri:dev

# Production build
npm run tauri:build
```

## First Steps

### 1. Check Your Environment

```bash
soliloquy-build env check
```

This verifies that all required build tools are available.

### 2. View Build Statistics

```bash
soliloquy-build stats
```

### 3. List Project Modules

```bash
soliloquy-build module list
```

### 4. Start a Build

```bash
# Bazel build
soliloquy-build start //src/shell:soliloquy_shell --system bazel

# GN + Ninja build
soliloquy-build start shell --system gn

# Cargo build
soliloquy-build start soliloquy-shell --system cargo
```

### 5. View Build Status

```bash
# List active builds
soliloquy-build status

# Check specific build
soliloquy-build status <build-id>
```

## Common Workflows

### Development Workflow

```bash
# 1. Check environment
soliloquy-build env check

# 2. Start a build
soliloquy-build start //src/shell:soliloquy_shell -s bazel -v

# 3. Monitor progress
soliloquy-build status --follow

# 4. Run tests
soliloquy-build test run //test/vm:tests
```

### Module Exploration

```bash
# List all modules
soliloquy-build module list

# Get module information
soliloquy-build module info soliloquy_shell

# View dependencies
soliloquy-build module deps soliloquy_shell

# View reverse dependencies
soliloquy-build module deps soliloquy_shell --reverse
```

### Build Analysis

```bash
# View statistics
soliloquy-build stats

# View build history (last 7 days)
soliloquy-build history

# View last 30 days
soliloquy-build history --days 30

# Compare two builds
soliloquy-build compare <build-id-1> <build-id-2>
```

### Development Tools

```bash
# Generate FIDL bindings
soliloquy-build fidl generate

# List available FIDL libraries
soliloquy-build fidl list

# Translate C to V
soliloquy-build c2v translate kernel/lib/libc

# Dry run translation
soliloquy-build c2v translate kernel/lib/libc --dry-run

# Check translation status
soliloquy-build c2v status
```

## GUI Quick Start

### Launch the GUI

```bash
# From the GUI directory
cd tools/build_manager/build_manager_gui
npm run tauri:dev
```

Or run the installed application from your applications menu.

### Key Features

1. **Dashboard**: Overview of build statistics and quick actions
2. **Build View**: Start and monitor builds with live output
3. **Modules**: Browse and explore project modules
4. **Tests**: Run and view test results (coming soon)
5. **Analytics**: View build history and trends
6. **Settings**: Configure build preferences

### Navigation

- Use the sidebar to navigate between views
- Click on modules to view details
- Use the search box to filter modules
- Select different time ranges in analytics

## Configuration

### Config File Location

- Linux: `~/.config/soliloquy-build/config.toml`
- macOS: `~/Library/Application Support/soliloquy-build/config.toml`

### Example Configuration

```toml
[general]
project_root = "/path/to/soliloquy"
default_build_system = "bazel"
parallel_jobs = 8
log_level = "info"

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

## Tips & Tricks

### CLI Tips

1. **Use aliases**: Add to your shell config:
   ```bash
   alias sb='soliloquy-build'
   alias sbs='soliloquy-build start'
   alias sbst='soliloquy-build status'
   ```

2. **Tab completion**: Most shells support tab completion for commands

3. **Verbose output**: Add `-v` to see detailed build information

4. **Clean builds**: Add `--clean` to start fresh

### GUI Tips

1. **Keyboard shortcuts**: Use arrow keys to navigate module list

2. **Multi-selection**: Hold Ctrl/Cmd to select multiple modules

3. **Quick search**: Press `/` to focus search box

4. **Dark theme**: Optimized for long coding sessions

## Troubleshooting

### CLI not found after install

```bash
# Add Cargo bin to PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Add to shell config (.bashrc, .zshrc, etc.)
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
```

### GUI won't start

```bash
# Check Node.js version (18+ required)
node --version

# Reinstall dependencies
cd tools/build_manager/build_manager_gui
rm -rf node_modules package-lock.json
npm install
```

### Database errors

```bash
# Reset database
rm ~/.local/share/soliloquy-build/analytics.db  # Linux
rm ~/Library/Application\ Support/soliloquy-build/analytics.db  # macOS
```

### Build system not found

```bash
# Verify tools are installed and in PATH
soliloquy-build env check

# Install missing tools
# Bazel: https://bazel.build/install
# GN/Ninja: via setup_sdk.sh
# Cargo: https://rustup.rs/
```

## Next Steps

- Read the [full documentation](README.md)
- Explore [all features](FEATURES.md)
- Check out [examples](examples/)
- Join our community discussions

## Getting Help

- Run `soliloquy-build --help` for command reference
- Check the documentation in `tools/build_manager/README.md`
- Report issues on the project tracker
- Ask questions in team chat

## What's Next?

Now that you have the build manager running, try:

1. Build your first target
2. Explore module dependencies
3. View build analytics
4. Set up your preferred configuration
5. Try the GUI application

Happy building! 🚀
