# Component Manifest Quick Reference

Quick commands and tips for working with the Soliloquy Shell component manifest.

## Quick Commands

### Validate Manifest
```bash
# Full validation (requires cmc tool)
./tools/soliloquy/validate_manifest.sh

# Basic structure check (no tools required)
./tools/soliloquy/test_manifest_structure.sh

# Validation is automatic during build
./tools/soliloquy/build.sh
```

### Build Package
```bash
# Full source build (produces .far)
./tools/soliloquy/build.sh

# SDK-only build
./tools/soliloquy/build_sdk.sh

# Bazel build
bazel build //src/shell:soliloquy_shell
```

### Check Output
```bash
# Find the .far file
find . -name "soliloquy_shell.far" -type f

# Common locations:
# - fuchsia/fuchsia/out/default/obj/src/shell/soliloquy_shell.far
# - out/arm64/soliloquy_shell.far
# - bazel-bin/src/shell/soliloquy_shell.far
```

## Manifest Structure at a Glance

```cml
{
    include: [ "syslog/client.shard.cml" ],
    
    program: {
        runner: "elf",
        binary: "bin/soliloquy_shell",
    },
    
    capabilities: [
        // What we provide to others
        { protocol: [ "fuchsia.ui.app.ViewProvider" ] },
    ],
    
    use: [
        {
            protocol: [
                // What we need from the system
                "fuchsia.logger.LogSink",          // Logging
                "fuchsia.ui.composition.Flatland", // Graphics
                "fuchsia.ui.composition.Allocator",// Buffer allocation
                "fuchsia.ui.views.ViewRefInstalled",// View lifecycle
                "fuchsia.ui.pointer.TouchSource",  // Touch input
                "fuchsia.ui.input3.Keyboard",      // Keyboard input
                "fuchsia.vulkan.loader.Loader",    // Vulkan graphics
                "fuchsia.net.name.Lookup",         // DNS
                "fuchsia.posix.socket.Provider",   // Network sockets
            ],
        },
        {
            storage: "data",  // Persistent storage
            path: "/data",
        },
    ],
    
    expose: [
        // Make our capabilities available to parent
        { protocol: [ "fuchsia.ui.app.ViewProvider" ], from: "self" },
    ],
}
```

## Protocol Reference

| Protocol | Purpose | Code Location |
|----------|---------|---------------|
| `fuchsia.logger.LogSink` | System logging | `main.rs` |
| `fuchsia.ui.composition.Flatland` | Graphics composition | `servo_embedder.rs`, `zircon_window.rs` |
| `fuchsia.ui.composition.Allocator` | Buffer allocation | Flatland rendering |
| `fuchsia.ui.views.ViewRefInstalled` | View lifecycle | Window management |
| `fuchsia.ui.pointer.TouchSource` | Touch input | `servo_embedder.rs` |
| `fuchsia.ui.input3.Keyboard` | Keyboard input | `servo_embedder.rs` |
| `fuchsia.vulkan.loader.Loader` | Vulkan graphics | `zircon_window.rs` |
| `fuchsia.net.name.Lookup` | DNS resolution | `servo_embedder.rs` |
| `fuchsia.posix.socket.Provider` | Network sockets | Servo network stack |

## Adding a New Protocol

1. **Add to manifest** (`src/shell/meta/soliloquy_shell.cml`):
   ```cml
   protocol: [
       // ... existing protocols
       
       // Brief description of what it's for
       // Code path: file.rs
       "fuchsia.new.Protocol",
   ]
   ```

2. **Validate**:
   ```bash
   ./tools/soliloquy/validate_manifest.sh
   ```

3. **Update code** to use the protocol

4. **Test**:
   ```bash
   ./tools/soliloquy/build.sh
   ```

## Common Issues

### Validation Fails
```bash
# Check structure first
./tools/soliloquy/test_manifest_structure.sh

# Check for syntax errors
cmc format --check src/shell/meta/soliloquy_shell.cml

# Auto-fix formatting
cmc format --in-place src/shell/meta/soliloquy_shell.cml
```

### Protocol Not Available at Runtime
1. Check manifest includes the protocol in `use` section
2. Check parent component offers the protocol
3. Check product/board configuration
4. Check logs: `fx log --tag soliloquy_shell`

### Build Fails on Manifest
1. Run validation script to get specific error
2. Check manifest syntax (valid JSON5)
3. Ensure all protocols are properly quoted
4. Check for missing commas or brackets

## File Locations

| File | Purpose |
|------|---------|
| `src/shell/meta/soliloquy_shell.cml` | Component manifest (source) |
| `src/shell/BUILD.gn` | Build configuration |
| `build/packages/soliloquy_shell/` | Packaging configuration |
| `tools/soliloquy/validate_manifest.sh` | Validation script |
| `docs/component_manifest.md` | Comprehensive guide |

## Further Reading

- [Component Manifest Guide](component_manifest.md) - Comprehensive documentation
- [Build Guide](build.md) - Build system documentation
- [Fuchsia Component Manifests](https://fuchsia.dev/fuchsia-src/concepts/components/v2/component_manifests)
- [FIDL Protocol Reference](https://fuchsia.dev/reference/fidl)
