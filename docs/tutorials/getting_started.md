# Getting Started with Soliloquy Development

This tutorial will walk you through setting up your development environment and building your first Soliloquy component.

## Prerequisites

Before you begin, ensure you have:

- **Operating System**: macOS 10.15+ or Linux (Fedora/RHEL/Debian/Ubuntu)
- **Disk Space**: 10GB+ for SDK, 50GB+ for full source
- **Internet Connection**: For downloading dependencies
- **Time**: ~30 minutes for SDK setup, ~2 hours for full source

## Choose Your Setup Path

### Path A: SDK-Based (Recommended for Beginners)
- ✅ Works on macOS and Linux
- ✅ Faster setup (~30 minutes)
- ✅ Smaller disk footprint (10GB)
- ✅ Ideal for component development
- ❌ Cannot modify Zircon kernel

### Path B: Full Source (Advanced)
- ✅ Complete Fuchsia source tree
- ✅ Can modify kernel and drivers
- ✅ Full build from source
- ❌ Linux only
- ❌ Longer setup (~2 hours)
- ❌ Large disk space (50GB+)

**For this tutorial, we'll use Path A (SDK-based setup).**

---

## Step 1: Clone the Repository

```bash
# Clone Soliloquy
git clone https://github.com/yourusername/soliloquy.git
cd soliloquy
```

---

## Step 2: Install System Dependencies

### macOS

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Homebrew will handle dependencies automatically
```

### Linux (Debian/Ubuntu)

```bash
sudo apt-get update
sudo apt-get install -y \
  curl wget git \
  build-essential \
  python3 python3-pip \
  clang
```

### Linux (Fedora/RHEL)

```bash
sudo dnf install -y \
  curl wget git \
  gcc gcc-c++ make \
  python3 python3-pip \
  clang
```

---

## Step 3: Install Bazelisk

Bazelisk automatically downloads and manages the correct Bazel version.

### macOS

```bash
brew install bazelisk
```

### Linux

```bash
# Download Bazelisk
wget https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64

# Install
chmod +x bazelisk-linux-amd64
sudo mv bazelisk-linux-amd64 /usr/local/bin/bazel

# Verify
bazel --version
```

---

## Step 4: Download Fuchsia SDK

The SDK contains all necessary Fuchsia libraries and tools.

```bash
./tools/soliloquy/setup_sdk.sh
```

**What this does**:
- Downloads Fuchsia SDK (~2.3GB)
- Extracts to `sdk/` directory
- Configures build paths
- Validates installation

**Time**: ~10-15 minutes depending on internet speed

---

## Step 5: Set Up Environment

```bash
# Load environment variables
source tools/soliloquy/env.sh

# Verify environment
echo $FUCHSIA_SDK_PATH
# Should print: /path/to/soliloquy/sdk
```

**Tip**: Add this to your shell profile (`.bashrc` or `.zshrc`):
```bash
alias soliloquy-env='cd ~/path/to/soliloquy && source tools/soliloquy/env.sh'
```

---

## Step 6: Verify Installation

Run verification scripts to ensure everything is set up correctly:

```bash
# Verify test framework
./tools/scripts/verify_test_framework.sh

# Verify C2V tooling (optional)
./tools/scripts/verify_c2v_setup.sh
```

Expected output:
```
========================================
Test Framework Verification
========================================

✓ Checking test framework files...
  SUCCESS: Test framework files exist
✓ All checks passed!
```

---

## Step 7: Build Your First Component

Let's build the Soliloquy shell component:

```bash
# Build the shell
bazel build //src/shell:soliloquy_shell_simple
```

**What's happening**:
- Bazel downloads required dependencies
- Compiles Rust source code
- Links against Fuchsia SDK libraries
- Creates executable component

**Time**: First build ~5-10 minutes (caching makes subsequent builds faster)

**Expected output**:
```
INFO: Build completed successfully, 42 total actions
```

---

## Step 8: Explore Build Outputs

```bash
# View build artifacts
ls -lh bazel-bin/src/shell/

# Example outputs:
# soliloquy_shell_simple       - Executable
# soliloquy_shell_simple.meta  - Component metadata
```

---

## Step 9: Run Tests

Ensure your build is working correctly:

```bash
# Run all tests
bazel test //...

# Run specific test suite
bazel test //test/vm:tests
```

---

## Step 10: Build More Targets

```bash
# Build all targets
bazel build //...

# Build SDK libraries
bazel build //sdk:libs

# List all available targets
bazel query //...
```

---

## Next Steps

### Learn the Development Workflow

1. **Read the Developer Guide**: [guides/dev_guide.md](../guides/dev_guide.md)
2. **Understand the Architecture**: [architecture/architecture.md](../architecture/architecture.md)
3. **Explore Testing**: [guides/getting_started_with_testing.md](../guides/getting_started_with_testing.md)

### Try Component Development

Create a simple component:

```bash
# Create component directory
mkdir -p src/my_component

# Create source file
cat > src/my_component/main.v << 'EOF'
module main

import fuchsia.sys

fn main() {
    println('Hello from Soliloquy!')
}
EOF

# Create BUILD.bazel
cat > src/my_component/BUILD.bazel << 'EOF'
load("@rules_rust//rust:defs.bzl", "rust_binary")

rust_binary(
    name = "my_component",
    srcs = ["main.rs"],
    edition = "2021",
    visibility = ["//visibility:public"],
)
EOF

# Build it
bazel build //src/my_component:my_component
```

### Explore UI Development

```bash
# Start UI development server
./tools/soliloquy/dev_ui.sh
```

This launches the Tauri-based UI prototype with hot reload.

### Port a Driver

Follow the [Driver Porting Guide](../guides/driver_porting.md) to port hardware drivers.

### Contribute

Ready to contribute? See [Contributing Guide](../contibuting.md).

---

## Troubleshooting

### Build Fails with "SDK not found"

```bash
# Re-run SDK setup
./tools/soliloquy/setup_sdk.sh

# Reload environment
source tools/soliloquy/env.sh
```

### Bazel Cache Issues

```bash
# Clean build cache
bazel clean --expunge

# Rebuild
bazel build //src/shell:soliloquy_shell_simple
```

### Permission Denied Errors

```bash
# Make scripts executable
chmod +x tools/soliloquy/*.sh
chmod +x tools/scripts/*.sh
```

### "Command not found: bazel"

Ensure Bazelisk is installed and in your PATH:

```bash
# Check installation
which bazel

# Add to PATH if needed
export PATH="$HOME/.local/bin:$PATH"
```

---

## Common Commands Reference

| Task | Command |
|------|---------|
| Load environment | `source tools/soliloquy/env.sh` |
| Build all | `bazel build //...` |
| Run tests | `bazel test //...` |
| Clean build | `bazel clean` |
| Update SDK | `./tools/soliloquy/setup_sdk.sh` |
| Verify setup | `./tools/scripts/verify_test_framework.sh` |
| Start UI dev | `./tools/soliloquy/dev_ui.sh` |

---

## Getting Help

- **Documentation**: [docs/INDEX.md](../INDEX.md)
- **Issues**: GitHub Issues
- **Tools Reference**: [guides/tools_reference.md](./tools_reference.md)

---

**Congratulations!** 🎉 You've successfully set up Soliloquy and built your first component. Happy coding!
