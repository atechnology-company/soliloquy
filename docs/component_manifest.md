# Soliloquy Shell Component Manifest

This document explains the component manifest structure, capability routing, validation process, and packaging for the Soliloquy Shell.

## Overview

The Soliloquy Shell is a Fuchsia component that provides a web browser shell using the Servo rendering engine. It is packaged as a Fuchsia component with a Component Manifest Language (CML) file that declares all required capabilities and routing.

## Manifest Location

The shell's component manifest is located at:
```
src/shell/meta/soliloquy_shell.cml
```

## Manifest Structure

### Program Declaration

```cml
program: {
    runner: "elf",
    binary: "bin/soliloquy_shell",
}
```

The shell runs as an ELF binary using the standard Fuchsia ELF runner.

### Capabilities

The shell provides one capability to the system:

- **`fuchsia.ui.app.ViewProvider`**: Allows other components to embed the shell as a graphical view

This is exposed via the `expose` section so parent components or the system can use the shell as a view.

### Used Protocols

The shell uses the following FIDL protocols:

#### Graphics & UI

- **`fuchsia.ui.composition.Flatland`**
  - Used for: Modern composition API for rendering
  - Code path: `servo_embedder.rs` (FlatlandSession), `zircon_window.rs` (window presentation)
  - Required for: Displaying web content on screen

- **`fuchsia.ui.composition.Allocator`**
  - Used for: Allocating image buffers for Flatland
  - Code path: Implicit in Flatland rendering pipeline
  - Required for: Creating buffers to hold rendered frames

- **`fuchsia.ui.views.ViewRefInstalled`**
  - Used for: Tracking view lifecycle
  - Code path: View management in window system
  - Required for: Knowing when view is ready for input/presentation

- **`fuchsia.vulkan.loader.Loader`**
  - Used for: Loading Vulkan driver for GPU acceleration
  - Code path: `zircon_window.rs` (Magma/Vulkan interface)
  - Required for: Hardware-accelerated rendering

#### Input

- **`fuchsia.ui.pointer.TouchSource`**
  - Used for: Touch input events
  - Code path: `servo_embedder.rs` (InputEvent::Touch handling)
  - Required for: Touch gestures in web content

- **`fuchsia.ui.input3.Keyboard`**
  - Used for: Keyboard input events
  - Code path: `servo_embedder.rs` (InputEvent::Key handling)
  - Required for: Keyboard interaction with web pages

#### Networking

- **`fuchsia.net.name.Lookup`**
  - Used for: DNS resolution
  - Code path: `servo_embedder.rs` (load_url)
  - Required for: Resolving domain names when loading URLs

- **`fuchsia.posix.socket.Provider`**
  - Used for: Network sockets for HTTP/HTTPS
  - Code path: Servo's network stack
  - Required for: Fetching web resources

#### System

- **`fuchsia.logger.LogSink`**
  - Used for: Logging to system log
  - Code path: `main.rs` (fuchsia_syslog::init, log macros)
  - Required for: Diagnostics and debugging

### Storage

- **`data` storage**
  - Mount path: `/data`
  - Used for: Persistent storage for Servo
  - Contents: Cookies, cache, local storage, IndexedDB, service workers
  - Code path: Servo's storage APIs

## Capability Routing Diagram

```
┌─────────────────────────────────────┐
│         System/Parent               │
│                                     │
│  Provides:                          │
│  • All FIDL protocols               │
│  • Storage capabilities             │
└────────────┬────────────────────────┘
             │ Routes capabilities
             ▼
┌─────────────────────────────────────┐
│      soliloquy_shell                │
│                                     │
│  Uses (consumes):                   │
│  • fuchsia.ui.composition.Flatland  │
│  • fuchsia.ui.composition.Allocator │
│  • fuchsia.ui.views.ViewRefInstalled│
│  • fuchsia.ui.pointer.TouchSource   │
│  • fuchsia.ui.input3.Keyboard       │
│  • fuchsia.vulkan.loader.Loader     │
│  • fuchsia.net.name.Lookup          │
│  • fuchsia.posix.socket.Provider    │
│  • fuchsia.logger.LogSink           │
│  • storage: data                    │
│                                     │
│  Exposes (provides):                │
│  • fuchsia.ui.app.ViewProvider      │
└─────────────────────────────────────┘
             │ Exposes ViewProvider
             ▼
┌─────────────────────────────────────┐
│      Other Components/System        │
│  (can embed shell as a view)        │
└─────────────────────────────────────┘
```

## Validating the Manifest

### Using the Validation Script

The repository includes a validation script that checks the manifest for correctness:

```bash
./tools/soliloquy/validate_manifest.sh
```

This script:
1. Locates the `cmc` (Component Manifest Compiler) tool from the Fuchsia SDK
2. Runs `cmc validate` on the manifest
3. Optionally checks formatting

### Manual Validation

If you have `cmc` in your PATH or FUCHSIA_DIR set:

```bash
# Validate the manifest
cmc validate src/shell/meta/soliloquy_shell.cml

# Check formatting
cmc format --check src/shell/meta/soliloquy_shell.cml

# Auto-format the manifest
cmc format --in-place src/shell/meta/soliloquy_shell.cml
```

### Integrated Validation

The validation script is automatically run during the build process:

```bash
./tools/soliloquy/build.sh
```

This ensures that manifest regressions are caught before building the entire system.

### Common Validation Errors

1. **Unknown protocol**: Protocol not available in the Fuchsia SDK version
   - Solution: Check protocol availability for your SDK version
   - Refer to: https://fuchsia.dev/reference/fidl

2. **Invalid route**: Capability not properly routed from parent
   - Solution: Ensure parent component offers the capability
   - Check board configuration and product definition

3. **Syntax errors**: JSON5 formatting issues
   - Solution: Run `cmc format --in-place` to auto-fix
   - Check for missing commas, brackets, or quotes

4. **Duplicate capabilities**: Same protocol listed multiple times
   - Solution: Remove duplicates, ensure each protocol appears once

## Packaging

### GN Build System

The shell is packaged using GN (Generate Ninja) build files.

#### Primary Build Target

Located at `src/shell/BUILD.gn`:

```gn
rustc_binary("bin") {
  name = "soliloquy_shell"
  # ... sources and deps
}

fuchsia_component("component") {
  component_name = "soliloquy_shell"
  manifest = "meta/soliloquy_shell.cml"
  deps = [ ":bin" ]
}

fuchsia_package("soliloquy_shell") {
  package_name = "soliloquy_shell"
  deps = [ ":component" ]
}
```

This produces `soliloquy_shell.far` (Fuchsia Archive) containing:
- The compiled binary
- The component manifest
- Metadata and routing information

#### Packaging Target

A convenience target is available at `build/packages/soliloquy_shell/BUILD.gn`:

```gn
group("soliloquy_shell_pkg") {
  deps = [ "//src/shell:soliloquy_shell" ]
}
```

### Build Commands

#### Full Source Build

```bash
# Setup Fuchsia source (first time only)
./tools/soliloquy/setup.sh

# Source the Fuchsia environment
source fuchsia/fuchsia/scripts/fx-env.sh

# Build the shell package
./tools/soliloquy/build.sh
```

Output location: `fuchsia/fuchsia/out/default/obj/src/shell/soliloquy_shell.far`

#### SDK-Only Build

```bash
# Setup Fuchsia SDK (first time only)
./tools/soliloquy/setup_sdk.sh

# Source the SDK environment
source tools/soliloquy/env.sh

# Build using the SDK
./tools/soliloquy/build_sdk.sh
```

Output location: `out/arm64/soliloquy_shell.far`

### Build Output Structure

After a successful build, the `.far` file contains:

```
soliloquy_shell.far
├── meta/
│   ├── package               # Package metadata
│   ├── contents              # File manifest
│   └── soliloquy_shell.cm    # Compiled component manifest
└── bin/
    └── soliloquy_shell       # Binary executable
```

### Bazel Build (Alternative)

The shell can also be built with Bazel:

```bash
# Build with Bazel
./tools/soliloquy/build_bazel.sh

# Or directly
bazel build //src/shell:soliloquy_shell
```

Output location: `bazel-bin/src/shell/soliloquy_shell.far`

## Integration with fx build

The shell package is automatically included in system builds via the board configuration.

### Board Configuration

In `boards/arm64/soliloquy/BUILD.gn` (or similar board files), the shell is referenced:

```gn
# Board packages
board_packages += [ "//src/shell:soliloquy_shell" ]
```

### Product Configuration

When running `fx set`, the shell is added to the build:

```bash
fx set minimal.arm64 \
  --with-base //src/connectivity/network \
  --with-base //src/graphics/display \
  --with //src/shell:soliloquy_shell
```

The `--with` flag adds the package to the base set, ensuring it's included in the system image.

## Updating the Manifest

When adding new capabilities:

1. **Add the protocol to the manifest**:
   ```cml
   protocol: [
       // ... existing protocols
       "fuchsia.new.Protocol",
   ]
   ```

2. **Add a comment explaining its use**:
   ```cml
   // New feature: description of what it's used for
   // Code path: file.rs function
   "fuchsia.new.Protocol",
   ```

3. **Validate the manifest**:
   ```bash
   ./tools/soliloquy/validate_manifest.sh
   ```

4. **Update this documentation** if the capability is significant

5. **Ensure parent routing** - verify the protocol is available in the board/product configuration

## Troubleshooting

### Build Errors

**Error**: `Package 'soliloquy_shell' not found`
- Solution: Ensure the package is added to the build with `--with` or in board config
- Run: `fx set minimal.arm64 --with //src/shell:soliloquy_shell`

**Error**: `Missing capability: fuchsia.xyz.Protocol`
- Solution: Add the protocol to the manifest's `use` section
- Validate: `./tools/soliloquy/validate_manifest.sh`

### Runtime Errors

**Error**: `Failed to connect to protocol`
- Check: Protocol is listed in manifest's `use` section
- Check: Protocol is offered by parent component or system
- Debug: `fx log --tag soliloquy_shell`

**Error**: `Component failed to start`
- Check: Binary path is correct in manifest (`bin/soliloquy_shell`)
- Check: All dependencies are built and packaged
- Debug: `fx log --severity ERROR`

### Validation Errors

**Error**: `cmc: command not found`
- Solution: Run setup script to get Fuchsia SDK
- Run: `./tools/soliloquy/setup_sdk.sh`

**Error**: `Manifest syntax error`
- Solution: Check JSON5 syntax (commas, brackets, quotes)
- Auto-fix: `cmc format --in-place src/shell/meta/soliloquy_shell.cml`

## References

- [Fuchsia Component Manifests (CML)](https://fuchsia.dev/fuchsia-src/concepts/components/v2/component_manifests)
- [Component Capabilities](https://fuchsia.dev/fuchsia-src/concepts/components/v2/capabilities)
- [FIDL Protocol Reference](https://fuchsia.dev/reference/fidl)
- [Fuchsia Packages](https://fuchsia.dev/fuchsia-src/concepts/packages/package)
- [Component Manager](https://fuchsia.dev/fuchsia-src/concepts/components/v2/component_manager)

## See Also

- [build.md](build.md) - General build documentation
- [servo_integration.md](servo_integration.md) - Servo-specific integration details
- [DEVELOPER_GUIDE.md](../DEVELOPER_GUIDE.md) - Getting started guide
