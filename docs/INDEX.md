# Soliloquy OS Documentation Index

Welcome to the Soliloquy OS documentation! This index helps you find the information you need.

## Getting Started

- **[README](../readme.md)** - Project overview and quick start
- **[Developer Guide](./dev_guide.md)** - Comprehensive development guide
- **[Getting Started with Testing](./getting_started_with_testing.md)** - How to run and write tests
- **[Architecture](./ARCHITECTURE.md)** - System architecture overview

## Building and Development

- **[Build Guide](./build.md)** - Building the project (GN, Bazel, Cargo)
- **[Component Manifest](./component_manifest.md)** - Component structure and manifests
- **[Driver Porting](./driver_porting.md)** - Porting drivers to Soliloquy
- **[Contributing](./contibuting.md)** - Contribution guidelines

## Testing

- **[Testing Overview](./TESTING.md)** - Testing strategy and frameworks
- **[Testing Guide](./testing.md)** - Detailed testing documentation
- **[Test Coverage](./test_coverage_broadening.md)** - Expanding test coverage
- **[Quick Reference Manifest](./QUICK_REFERENCE_MANIFEST.md)** - Test command quick reference

## Special Topics

### Servo Integration
- **[Servo Integration](./servo_integration.md)** - Servo browser engine integration

### UI and Graphics
- **[UI Documentation](./ui/)** - UI framework and FIDL bindings

### C-to-V Translation
- **[C-to-V Translation Guide](./c2v_translations.md)** - Comprehensive guide to C-to-V translation
- **[Zircon C2V Workflow](./zircon_c2v.md)** - Detailed c2v workflow and tooling
- **[C2V Tooling Summary](./C2V_TOOLING_SUMMARY.md)** - Tooling setup and usage
- **[HAL Translation Summary](./HAL_TRANSLATION_SUMMARY.md)** - HAL subsystem translation details

## Subsystem Documentation

### Hardware Abstraction Layer (HAL)
- **Location**: `third_party/zircon_v/hal/`
- **[HAL README](../third_party/zircon_v/hal/README.md)** - V translation of HAL
- **[C HAL README](../third_party/zircon_c/hal/README.md)** - Original C++ sources
- **[HAL Translation Summary](./HAL_TRANSLATION_SUMMARY.md)** - Translation approach and status

### Virtual Memory (VM)
- **Location**: `third_party/zircon_v/vm/`
- **[VM README](../third_party/zircon_v/vm/README.md)** - V translation of VM subsystem
- **[C VM README](../third_party/zircon_c/vm/README.md)** - Original C sources

### Inter-Process Communication (IPC)
- **Location**: `third_party/zircon_v/ipc/`
- **[IPC README](../third_party/zircon_v/ipc/README.md)** - V translation of IPC subsystem
- **[C IPC README](../third_party/zircon_c/ipc/README.md)** - Original C sources

## Project Reports

- **[Ticket Completion Report](./TICKET_COMPLETION_REPORT.md)** - Completed work tracking

## Tools and Scripts

### Build Tools
- `tools/soliloquy/setup.sh` - Full Fuchsia source bootstrap
- `tools/soliloquy/setup_sdk.sh` - SDK-only setup
- `tools/soliloquy/env.sh` - Environment setup helper

### C-to-V Translation Tools
- `tools/soliloquy/c2v_pipeline.sh` - C-to-V translation pipeline
- `build/v_compile.py` - V compilation wrapper
- `build/v_translate.py` - C-to-V translation wrapper

### FIDL Tools
- `tools/soliloquy/gen_fidl_bindings.sh` - Generate Rust FIDL bindings

### Verification Scripts
- `verify_hal_v_translation.sh` - Verify HAL V translation
- `verify_vm_translation.sh` - Verify VM V translation  
- `verify_c2v_setup.sh` - Verify c2v tooling setup
- `verify_test_framework.sh` - Verify test framework

## Quick Command Reference

### Build Commands
```bash
# Bazel build
bazel build //target/path:target_name

# Build HAL
bazel build //drivers/common/soliloquy_hal:soliloquy_hal

# Build V translations
bazel build //third_party/zircon_v:zircon_v_hal
```

### Test Commands
```bash
# Run all tests
bazel test //...

# Run specific test suite
bazel test //drivers/common/soliloquy_hal/tests:all
bazel test //src/shell:soliloquy_shell_tests
```

### C-to-V Translation
```bash
# Bootstrap V toolchain
./tools/soliloquy/c2v_pipeline.sh --bootstrap-only

# Translate subsystem
./tools/soliloquy/c2v_pipeline.sh \
  --subsystem <name> \
  --sources third_party/zircon_c/<name> \
  --out-dir third_party/zircon_v/<name>

# Verify translation
./verify_hal_v_translation.sh
```

### Development Workflow
```bash
# Setup environment
./tools/soliloquy/setup_sdk.sh
source tools/soliloquy/env.sh

# Build and test
bazel build //...
bazel test //...

# Generate FIDL bindings
./tools/soliloquy/gen_fidl_bindings.sh
```

## Documentation Structure

```
docs/
├── INDEX.md                          # This file
├── c2v_translations.md               # C-to-V translation guide
├── zircon_c2v.md                     # Zircon c2v workflow
├── C2V_TOOLING_SUMMARY.md            # C2V tooling summary
├── HAL_TRANSLATION_SUMMARY.md        # HAL translation details
├── TICKET_COMPLETION_REPORT.md       # Project tracking
├── ARCHITECTURE.md                   # System architecture
├── dev_guide.md                      # Developer guide
├── build.md                          # Build documentation
├── TESTING.md                        # Testing overview
├── testing.md                        # Testing details
├── test_coverage_broadening.md       # Test coverage
├── getting_started_with_testing.md   # Testing quick start
├── QUICK_REFERENCE_MANIFEST.md       # Command reference
├── component_manifest.md             # Component manifests
├── driver_porting.md                 # Driver porting
├── servo_integration.md              # Servo integration
├── contibuting.md                    # Contributing guide
└── ui/                               # UI documentation
    └── flatland_bindings.md          # FIDL bindings
```

## External Resources

- [Fuchsia Documentation](https://fuchsia.dev/)
- [Zircon Kernel Concepts](https://fuchsia.dev/fuchsia-src/concepts/kernel)
- [V Language Documentation](https://github.com/vlang/v/blob/master/doc/docs.md)
- [Bazel Documentation](https://bazel.build/)
- [GN Documentation](https://gn.googlesource.com/gn/+/main/docs/)

## Getting Help

If you can't find what you're looking for:

1. Check this index for related topics
2. Search the documentation directory: `grep -r "keyword" docs/`
3. Review the README files in subsystem directories
4. Check the verification scripts for examples

## Contributing to Documentation

When adding new documentation:

1. Add it to the `docs/` directory (not project root)
2. Update this INDEX.md with a link
3. Follow the existing documentation style
4. Include code examples where helpful
5. Add cross-references to related docs

---

**Last Updated**: 2024-11-26  
**Maintainer**: Soliloquy OS Team
