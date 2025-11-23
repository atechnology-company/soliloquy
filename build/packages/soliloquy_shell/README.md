# Soliloquy Shell Package

This directory contains the packaging configuration for the Soliloquy Shell component.

## Overview

The Soliloquy Shell is packaged as a Fuchsia Archive (`.far` file) that contains:
- The compiled `soliloquy_shell` binary
- The component manifest (`soliloquy_shell.cm`)
- Package metadata

## Building

### Using GN/fx

```bash
# Full source build
./tools/soliloquy/build.sh

# The package will be built automatically as part of the system build
```

### Direct Target Build

```bash
# From Fuchsia source directory
fx build //src/shell:soliloquy_shell

# Or using the convenience target
fx build //build/packages/soliloquy_shell:soliloquy_shell_pkg
```

## Output Location

After building, the package archive will be located at:

- **Full source build**: `fuchsia/fuchsia/out/default/obj/src/shell/soliloquy_shell.far`
- **SDK build**: `out/arm64/soliloquy_shell.far`

## Package Contents

The `.far` archive includes:

```
soliloquy_shell.far
├── meta/
│   ├── package               # Package name and version
│   ├── contents              # List of files in package
│   └── soliloquy_shell.cm    # Compiled component manifest (from .cml)
└── bin/
    └── soliloquy_shell       # Rust binary executable
```

## Manifest Validation

Before building, the manifest is validated:

```bash
./tools/soliloquy/validate_manifest.sh
```

This ensures the component manifest (`src/shell/meta/soliloquy_shell.cml`) is correct.

## Integration

The package is integrated into the system build via:

1. **Board configuration** - Added to board packages in board BUILD.gn files
2. **Product configuration** - Included via `fx set` with `--with` flag
3. **Build script** - Automatically included by `tools/soliloquy/build.sh`

## Documentation

For detailed information about the component manifest, capability routing, and packaging:

See [docs/component_manifest.md](../../../docs/component_manifest.md)
