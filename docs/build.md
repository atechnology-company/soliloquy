# Soliloquy Build System Guide

This guide covers the different build methods available for Soliloquy OS and helps you choose the right approach for your development environment.

## Build Method Decision Tree

Use this flowchart to determine the best build method for your situation:

```
Are you on macOS?
├─ Yes → Use Remote Build (ssh_build.sh)
│   ├─ Have Linux server with SSH access?
│   │   ├─ Yes → ssh_build.sh user@server
│   │   └─ No → Use SDK Build (requires Linux VM)
│   └─ Want to avoid full Fuchsia checkout?
│       └─ Yes → SDK Build (build_sdk.sh)
│
└─ No (Linux) → Can you checkout full Fuchsia source?
    ├─ Yes → Full Source Build (build.sh)
    │   ├─ Need custom product/board?
    │   │   └─ Yes → build.sh --product X --board Y
    │   └─ Standard Soliloquy build?
    │       └─ Yes → build.sh (uses defaults)
    └─ No → SDK Build (build_sdk.sh)
        └─ Or Bazel Build (build_bazel.sh) for component development
```

## Build Methods Overview

### 1. Full Source Build (`build.sh`)

**Best for:** Linux users with full Fuchsia checkout

**Pros:**
- Complete access to Fuchsia build system
- Full Soliloquy OS with all components
- Supports custom products and boards
- Native development experience

**Cons:**
- Requires ~100GB disk space
- Longer initial setup
- Linux-only

**Usage:**
```bash
# Default build (minimal.arm64 + soliloquy board)
./tools/soliloquy/build.sh

# Custom product and board
./tools/soliloquy/build.sh --product workbench_eng.arm64 --board boards/arm64/qemu

# With additional build arguments
./tools/soliloquy/build.sh --extra-args "--args=variant=eng"
```

**Output:** `fuchsia/fuchsia/out/default/`

---

### 2. Remote Build (`ssh_build.sh`)

**Best for:** macOS users with Linux server access

**Pros:**
- Develop from macOS, build on Linux
- Uses full Fuchsia build system remotely
- Real-time log streaming
- Automatic path detection for common setups

**Cons:**
- Requires SSH access to Linux machine
- Network dependency
- Remote storage requirements

**Usage:**
```bash
# Basic remote build (auto-detects paths)
./tools/soliloquy/ssh_build.sh user@linux-server

# Stream logs in real-time
./tools/soliloquy/ssh_build.sh --stream-logs user@linux-server

# Custom remote directory
./tools/soliloquy/ssh_build.sh --remote-dir /path/to/soliloquy user@server

# Use existing checkout, skip sync
./tools/soliloquy/ssh_build.sh --no-sync user@server

# Custom product/board
./tools/soliloquy/ssh_build.sh --product workbench.arm64 user@server
```

**Output:** Available on remote machine at `fuchsia/fuchsia/out/default/`

---

### 3. SDK Build (`build_sdk.sh`)

**Best for:** Cross-platform development, smaller builds

**Pros:**
- Works on macOS and Linux
- Smaller footprint (~10GB vs 100GB)
- Faster setup
- Good for component development

**Cons:**
- Limited to SDK components
- Cannot build full OS images
- May not include all Soliloquy-specific features

**Usage:**
```bash
# Default debug build for arm64
./tools/soliloquy/build_sdk.sh

# Release build
./tools/soliloquy/build_sdk.sh --release

# Different CPU architecture
./tools/soliloquy/build_sdk.sh --cpu x64
```

**Output:** `out/arm64/` or `out/x64/`

---

### 4. Bazel Build (`build_bazel.sh`)

**Best for:** Component development, CI/CD

**Pros:**
- Fast incremental builds
- Excellent for component work
- Cross-platform
- Good integration with IDEs

**Cons:**
- Limited to Soliloquy components
- Cannot build full Fuchsia system
- Requires SDK setup

**Usage:**
```bash
# Build all targets
./tools/soliloquy/build_bazel.sh

# Build specific target
./tools/soliloquy/build_bazel.sh --target //src/shell:soliloquy_shell

# With optimization flags
./tools/soliloquy/build_bazel.sh --target //src/shell:soliloquy_shell -- -c opt
```

**Output:** `bazel-bin/`

## Quick Start by Platform

### macOS Development

1. **Setup SDK for component work:**
   ```bash
   ./tools/soliloquy/setup_sdk.sh
   ./tools/soliloquy/build_sdk.sh
   ```

2. **Remote full build (if you have Linux server):**
   ```bash
   ./tools/soliloquy/ssh_build.sh --stream-logs user@your-linux-server
   ```

3. **Bazel for component development:**
   ```bash
   ./tools/soliloquy/build_bazel.sh --target //src/shell:soliloquy_shell
   ```

### Linux Development

1. **Full source build (recommended):**
   ```bash
   ./tools/soliloquy/setup.sh  # One-time setup
   ./tools/soliloquy/build.sh  # Subsequent builds
   ```

2. **SDK build for faster iteration:**
   ```bash
   ./tools/soliloquy/setup_sdk.sh
   ./tools/soliloquy/build_sdk.sh
   ```

## Build Artifacts

All build methods provide a summary of generated artifacts:

```
=== Build Artifact Summary ===
Build Type: Fuchsia Full Source Build
Output Directory: fuchsia/fuchsia/out/default

Key Artifacts:
  soliloquy_shell.far (2457600 bytes)
  zircon-a.zbi (8912896 bytes)
  recovery.efi (786432 bytes)
Total files: 1247
```

## Manifest Validation

Before building, you can validate component manifests to catch errors early:

```bash
# Validate the shell manifest
./tools/soliloquy/validate_manifest.sh

# Validation runs automatically during build.sh
./tools/soliloquy/build.sh
```

The validation script checks that all protocol declarations, capability routing, and manifest syntax are correct using the Fuchsia `cmc` (Component Manifest Compiler) tool.

For more details on component manifests, see [Component Manifest Guide](component_manifest.md).

## Common Workflows

### First-time Setup

```bash
# Linux - Full build setup
./tools/soliloquy/setup.sh
./tools/soliloquy/build.sh

# macOS - Component development
./tools/soliloquy/setup_sdk.sh
./tools/soliloquy/build_sdk.sh
```

### Iterative Development

```bash
# Component changes (fast)
./tools/soliloquy/build_bazel.sh --target //src/shell:soliloquy_shell

# Full system changes (Linux)
./tools/soliloquy/build.sh

# Full system changes (macOS)
./tools/soliloquy/ssh_build.sh --no-sync --stream-logs user@server
```

### Custom Configurations

```bash
# Different hardware targets
./tools/soliloquy/build.sh --board boards/arm64/qemu

# Development vs production
./tools/soliloquy/build.sh --product workbench_eng.arm64  # Development
./tools/soliloquy/build.sh --product minimal.arm64        # Production
```

## Troubleshooting

### Common Issues

1. **"fx command not found"**
   - Run `./tools/soliloquy/setup.sh` to bootstrap Fuchsia tooling
   - Ensure you're in the project root directory

2. **SSH connection failures**
   - Verify SSH access: `ssh user@server echo "OK"`
   - Check remote directory permissions
   - Use `--remote-dir` to specify correct path

3. **Build configuration conflicts**
   - Use `fx_set_idempotent` in build.sh to avoid reconfiguration
   - Clear build directory: `rm -rf fuchsia/fuchsia/out/default`

4. **SDK not found**
   - Run `./tools/soliloquy/setup_sdk.sh`
   - Check `sdk/` directory exists and contains `tools/`

### Getting Help

All build scripts support `--help` for detailed usage information:

```bash
./tools/soliloquy/build.sh --help
./tools/soliloquy/ssh_build.sh --help
./tools/soliloquy/build_sdk.sh --help
./tools/soliloquy/build_bazel.sh --help
```

## Performance Tips

1. **Use incremental builds:** All scripts support incremental builds by default
2. **Parallel builds:** Bazel and Ninja automatically use available CPU cores
3. **Remote caching:** Configure Bazel remote cache for team development
4. **SSD storage:** Full Fuchsia builds benefit greatly from fast storage

## Integration with IDEs

- **VS Code:** Use Bazel extension for `build_bazel.sh`
- **CLion:** Configure CMake to use SDK build outputs
- **Vim/Emacs:** Use build scripts with `makeprg` configuration