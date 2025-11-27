# Soliloquy Scripts

Consolidated build and development scripts for Soliloquy.

## Quick Start

```bash
# Development mode (backend + UI with hot reload)
./scripts/dev.sh

# Build everything
./scripts/build.sh

# Test display detection
./scripts/display_test.sh
```

## Available Scripts

| Script | Description |
|--------|-------------|
| `build.sh` | Main build orchestrator |
| `dev.sh` | Development mode with hot reload |
| `display_test.sh` | Test display detection |
| `lib/common.sh` | Shared shell functions |
| `zircon/utils.sh` | Zircon-specific utilities |
| `zircon/display_detect.sh` | Display detection on Zircon |

## Build Targets

```bash
./scripts/build.sh all       # Build everything
./scripts/build.sh backend   # V backend only
./scripts/build.sh ui        # Svelte UI only
./scripts/build.sh shell     # Servo shell (Bazel)
./scripts/build.sh fuchsia   # Full Fuchsia build (Linux)
```

## Build Options

```bash
./scripts/build.sh --release    # Release build
./scripts/build.sh --clean      # Clean before building
./scripts/build.sh --test       # Run tests after build
```

## Development Options

```bash
./scripts/dev.sh                # Start backend + UI
./scripts/dev.sh --backend-only # Backend only (headless testing)
./scripts/dev.sh --ui-only      # UI only (if backend already running)
./scripts/dev.sh --port 8080    # Custom backend port
```

## Display Detection Testing

```bash
# Real detection (queries backend API if running)
./scripts/display_test.sh

# Simulate headless mode
./scripts/display_test.sh --simulate-headless

# Simulate desktop mode
./scripts/display_test.sh --simulate-display

# JSON output
./scripts/display_test.sh --json
```

## Zircon Scripts

These scripts only work on Fuchsia/Zircon targets:

```bash
# Run on device
./scripts/zircon/display_detect.sh  # Test scenic display detection
```

## Legacy Scripts

The following scripts in `tools/soliloquy/` are still available for full Fuchsia source builds:

- `build.sh` - Full `fx build` workflow
- `setup.sh` - Bootstrap Fuchsia checkout
- `flash.sh` - Flash to device

For new development, prefer the scripts in `/scripts/`.
