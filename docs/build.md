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

## Bazel Build System (Advanced)

Soliloquy uses **Bazel with Bzlmod** for component-level development. This section covers the Bazel build workflow, module management, and troubleshooting.

### Understanding MODULE.bazel

The `MODULE.bazel` file defines external dependencies using Bazel's new module system (Bzlmod):

```python
# MODULE.bazel
module(
    name = "soliloquy",
    version = "0.1.0",
)

# Rust rules for building Rust targets
bazel_dep(name = "rules_rust", version = "0.56.0")

# C++ rules for driver development
bazel_dep(name = "rules_cc", version = "0.0.16")

# TODO: Add Fuchsia SDK integration via registry or local_path_override
```

**Key concepts:**
- `bazel_dep()`: Declares a dependency on a ruleset from the Bazel Central Registry
- Version resolution handled automatically by Bzlmod (no manual `WORKSPACE` maintenance)
- Module lock file (`MODULE.bazel.lock`) ensures reproducible builds

### Bazel Sync and Dependency Resolution

When you modify `MODULE.bazel` or first clone the repository:

```bash
# Fetch all external dependencies defined in MODULE.bazel
bazel sync --configure

# Or implicitly during first build
bazel build //...
```

**What happens during sync:**
1. Bazel reads `MODULE.bazel` and resolves the dependency graph
2. Downloads rulesets from the Bazel Central Registry (or local overrides)
3. Generates `MODULE.bazel.lock` with pinned versions and checksums
4. Caches artifacts in `~/.cache/bazel/` (Linux/macOS)

**MODULE.bazel.lock:**
- Tracks exact resolved versions of all transitive dependencies
- Should be committed to version control for reproducibility
- Regenerate with `bazel sync` after MODULE.bazel changes

### Building Specific Targets

#### Build the Soliloquy Shell

```bash
# Build the main shell component
bazel build //src/shell:soliloquy_shell

# Build with optimizations
bazel build //src/shell:soliloquy_shell -c opt

# Build for specific architecture
bazel build //src/shell:soliloquy_shell --cpu=arm64
```

#### Build All Targets

```bash
# Build everything in the repository
bazel build //...

# Build and run tests
bazel test //...

# Clean build (forces rebuild)
bazel clean --expunge
bazel build //src/shell:soliloquy_shell
```

#### Query Available Targets

```bash
# List all targets in the project
bazel query //...

# List targets in a specific package
bazel query //src/shell:all

# Show dependencies of a target
bazel query 'deps(//src/shell:soliloquy_shell)'
```

### Using the Build Script

For convenience, use the provided wrapper script:

```bash
# Build default targets
./tools/soliloquy/build_bazel.sh

# Build specific target
./tools/soliloquy/build_bazel.sh --target //src/shell:soliloquy_shell

# Pass additional Bazel flags
./tools/soliloquy/build_bazel.sh --target //src/shell:soliloquy_shell -- -c opt

# Run tests
./tools/soliloquy/build_bazel.sh --target //src/shell:all --test
```

### Troubleshooting Bazel Builds

#### 1. Missing SDK Repository

**Error:**
```
ERROR: no such package '@fuchsia_sdk//': The repository '@fuchsia_sdk' could not be resolved
```

**Solution:**
Ensure the Fuchsia SDK is set up and the repository rule is configured:
```bash
# Download SDK first
./tools/soliloquy/setup_sdk.sh

# Verify SDK directory exists
ls -la sdk/

# Rebuild
bazel clean
bazel build //src/shell:soliloquy_shell
```

If using local SDK override, ensure `MODULE.bazel` or `WORKSPACE.bazel` includes:
```python
# WORKSPACE.bazel
local_repository(
    name = "fuchsia_sdk",
    path = "sdk",
)
```

#### 2. Toolchain Download Issues

**Error:**
```
ERROR: Failed to download https://github.com/bazelbuild/rules_rust/releases/...
```

**Solution:**
Check network connectivity and retry with verbose output:
```bash
bazel sync --configure --verbose_failures

# If behind a proxy, configure Bazel:
bazel sync --configure \
  --http_proxy=http://proxy.example.com:8080 \
  --https_proxy=http://proxy.example.com:8080
```

**Alternative:** Use offline mode if artifacts are cached:
```bash
bazel build //src/shell:soliloquy_shell --offline
```

#### 3. Version Conflicts

**Error:**
```
ERROR: Module extension rules_rust~0.56.0~rust_toolchains conflicts with...
```

**Solution:**
Clear the module resolution cache and re-sync:
```bash
bazel shutdown
rm -rf $(bazel info output_base)
bazel sync --configure
```

#### 4. Stale MODULE.bazel.lock

**Error:**
```
ERROR: Lock file is out of date. Run 'bazel mod deps --lockfile_mode=update'
```

**Solution:**
Regenerate the lock file after MODULE.bazel changes:
```bash
bazel mod deps --lockfile_mode=update
git add MODULE.bazel.lock
```

#### 5. Compilation Errors in Rust Code

**Error:**
```
error[E0433]: failed to resolve: use of undeclared crate or module `fuchsia_async`
```

**Solution:**
Ensure the Rust target's `BUILD.bazel` declares all dependencies:
```python
rust_library(
    name = "soliloquy_shell",
    srcs = ["src/lib.rs"],
    deps = [
        "//sdk/rust:fuchsia-async",
        "//sdk/rust:fuchsia-component",
    ],
)
```

Verify Rust toolchain is correctly configured:
```bash
bazel query @rules_rust//rust:toolchains
```

#### 6. Missing Header Files (C++ Drivers)

**Error:**
```
fatal error: 'lib/ddk/device.h' file not found
```

**Solution:**
Add Fuchsia SDK includes to the `cc_library` or `cc_binary` target:
```python
cc_library(
    name = "my_driver",
    srcs = ["driver.cc"],
    deps = [
        "//sdk/c:ddk",
        "//drivers/common/soliloquy_hal",
    ],
    includes = ["sdk/include"],
)
```

### Bazel Performance Tips

1. **Remote Caching (Team Development):**
   ```bash
   # Configure remote cache in .bazelrc
   build --remote_cache=https://bazel-cache.example.com
   ```

2. **Local Disk Cache:**
   ```bash
   # Increase disk cache size (default 5GB)
   bazel build //... --disk_cache=~/.cache/bazel-disk --disk_cache_size=20GB
   ```

3. **Parallel Jobs:**
   ```bash
   # Limit concurrent jobs (useful on low-memory systems)
   bazel build //... --jobs=4
   ```

4. **Incremental Builds:**
   Bazel automatically caches intermediate artifacts. For best performance:
   - Don't use `--expunge` unless necessary
   - Keep `bazel-*` symlinks intact (don't `.gitignore` them)
   - Use `bazel build` (not `bazel run`) for repeated builds

### Bazel vs Other Build Methods

| Feature | Bazel | SDK Build (`build_sdk.sh`) | Full Build (`build.sh`) |
|---------|-------|---------------------------|-------------------------|
| **Speed** | Fast incremental | Moderate | Slow (full system) |
| **Scope** | Components only | Components + SDK libs | Entire Fuchsia OS |
| **Cache** | Excellent | Good | Limited |
| **Cross-platform** | Yes (Linux/macOS) | Yes | Linux only |
| **Use case** | Development iteration | SDK testing | System integration |

**When to use Bazel:**
- Iterating on Rust/C++ components
- Unit testing individual modules
- CI/CD pipelines for component validation
- Working without full Fuchsia source tree

**When to use full build:**
- Kernel modifications
- Driver integration testing
- Board-level configuration changes
- Creating flashable system images

## Integration with IDEs

- **VS Code:** Use Bazel extension for `build_bazel.sh`
- **CLion:** Configure CMake to use SDK build outputs
- **Vim/Emacs:** Use build scripts with `makeprg` configuration