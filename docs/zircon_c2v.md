# Zircon C-to-V Translation Workflow

This document describes the tooling and workflow for translating Zircon C subsystems to the V programming language using the `c2v` translator.

## Overview

The c2v translation effort aims to incrementally port critical Zircon kernel subsystems from C to V, a systems programming language with better memory safety guarantees and simpler syntax. The translation happens on a dedicated feature branch to avoid disrupting the main development branch.

## Branch Strategy

All c2v translation work happens on the `feature/zircon-c2v-subsystems` branch (or a related feature branch with that prefix). This ensures:

- Main branch remains stable with production C code
- Translation work can be reviewed and tested independently
- Gradual subsystem-by-subsystem migration path
- Easy rollback if needed

## Tooling Setup

### Prerequisites

- Linux or macOS with standard development tools (git, curl, unzip)
- Python 3.8+
- Fuchsia SDK or full Fuchsia source tree

### Installing the V Toolchain

The V toolchain and c2v translator are automatically downloaded and installed to `.build-tools/v/` when you first run the c2v pipeline:

```bash
# Bootstrap V toolchain only
./tools/soliloquy/c2v_pipeline.sh --bootstrap-only
```

This will:
1. Detect your OS and architecture (Linux/macOS, x64/arm64)
2. Download the appropriate V release binary
3. Install to `.build-tools/v/`
4. Make the `v` binary available for c2v translation

The `.build-tools/` directory is gitignored, so each developer needs to bootstrap their own V installation.

### Environment Setup

After bootstrapping, source the environment helper to expose V in your PATH:

```bash
source tools/soliloquy/env.sh
```

This sets:
- `V_HOME` - Path to V installation (`.build-tools/v/`)
- Adds V to your PATH
- Shows V version if installed

## c2v_pipeline.sh Usage

The main entry point for c2v translation is `tools/soliloquy/c2v_pipeline.sh`. It provides:

- Automatic V toolchain bootstrapping
- Subsystem translation with c2v
- Dry-run mode for validation
- Configurable output directories

### Command-Line Options

```bash
./tools/soliloquy/c2v_pipeline.sh [OPTIONS]

OPTIONS:
  --subsystem <name>     Target subsystem to translate (required for translate mode)
  --dry-run              Show what would be done without executing
  --out-dir <path>       Output directory for translated files (default: out/c2v)
  --bootstrap-only       Only download and setup V toolchain
  --help                 Show help message

ENVIRONMENT:
  V_HOME                 Path to V installation (default: .build-tools/v)
  V_VERSION              Version of V to install (default: latest)
```

### Examples

```bash
# Bootstrap V toolchain
./tools/soliloquy/c2v_pipeline.sh --bootstrap-only

# Translate a subsystem (dry-run to preview)
./tools/soliloquy/c2v_pipeline.sh --subsystem kernel/lib/libc --dry-run

# Translate a subsystem to custom output directory
./tools/soliloquy/c2v_pipeline.sh --subsystem kernel/lib/libc --out-dir out/translated/libc

# Use specific V version
export V_VERSION=0.4.3
./tools/soliloquy/c2v_pipeline.sh --bootstrap-only
```

## Build Integration

The c2v tooling is integrated into both GN and Bazel build systems through custom rules:

### GN Build Rules (`build/v_rules.gni`)

```gn
# Import V rules
import("//build/v_rules.gni")

# Compile V sources to object files
v_object("my_module") {
  sources = [ "src/module.v" ]
  output_name = "my_module"
}

# Translate C to V and compile
v_object("translated_libc") {
  sources = [ "kernel/lib/libc/string.c" ]
  translate_from_c = true
  output_name = "libc_string"
}

# Translate C to V without compiling
c2v_translate("libc_headers") {
  sources = [ 
    "kernel/lib/libc/string.h",
    "kernel/lib/libc/stdlib.h",
  ]
  output_dir = "${target_gen_dir}/libc"
}
```

### Bazel Build Rules (`build/v_rules.bzl`)

```python
load("//build:v_rules.bzl", "v_object", "c2v_translate")

# Compile V sources
v_object(
    name = "my_module",
    srcs = ["src/module.v"],
    output_name = "my_module",
)

# Translate C to V and compile
v_object(
    name = "translated_libc",
    srcs = ["kernel/lib/libc/string.c"],
    translate_from_c = True,
    output_name = "libc_string",
)

# Translate C to V without compiling
c2v_translate(
    name = "libc_headers",
    srcs = [
        "kernel/lib/libc/string.h",
        "kernel/lib/libc/stdlib.h",
    ],
)
```

### Smoke Test

A smoke test target is provided to verify the c2v tooling is correctly set up:

```bash
# GN build
gn gen out/c2v
ninja -C out/c2v c2v_tooling_smoke

# Bazel build
bazel build //:c2v_tooling_smoke
# or
bazel run //:c2v_tooling_smoke
```

## Translation Workflow

### Step 1: Select a Subsystem

Choose a subsystem from the priority list below. Start with smaller, self-contained libraries before tackling larger subsystems.

### Step 2: Dry-Run Translation

Preview the translation to identify potential issues:

```bash
./tools/soliloquy/c2v_pipeline.sh --subsystem kernel/lib/libc --dry-run
```

### Step 3: Run Translation

Execute the actual translation:

```bash
./tools/soliloquy/c2v_pipeline.sh --subsystem kernel/lib/libc --out-dir out/c2v/libc
```

### Step 4: Review and Fix

c2v produces mostly-correct V code, but manual review and fixes are needed for:

- Complex pointer arithmetic
- Inline assembly
- Macro expansions
- Platform-specific code
- Type casts and unions

### Step 5: Add Build Targets

Create GN and Bazel targets for the translated subsystem:

```gn
# BUILD.gn
import("//build/v_rules.gni")

v_library("libc_v") {
  sources = [ "out/c2v/libc/string.v" ]
  output_name = "libc_v"
}
```

### Step 6: Test

Write tests for the translated subsystem to ensure correctness:

```v
// test_string.v
module main

import libc_v

fn test_strlen() {
    assert libc_v.strlen('hello') == 5
}
```

### Step 7: Integrate

Once tested, integrate the V version alongside the C version for gradual rollout.

## Subsystem Priority List

Translation priority is based on:
- Size and complexity (smaller first)
- Dependencies (fewest dependencies first)
- Impact (high-value subsystems)
- Risk (low-risk libraries first)

### Phase 1: Foundation Libraries (Low Risk, High Value)

1. **kernel/lib/libc** - Standard C library functions
   - string.c (string manipulation)
   - stdlib.c (memory allocation, conversion)
   - ctype.c (character classification)
   
2. **kernel/lib/ktl** - Kernel Template Library
   - Basic data structures (array, span)
   - Algorithms (sort, search)
   
3. **kernel/lib/unittest** - Unit testing framework
   - Test harness and assertions

### Phase 2: Core Data Structures (Medium Risk)

4. **kernel/lib/fbl** - Fuchsia Base Library
   - Intrusive containers
   - Reference counting
   - String utilities

5. **kernel/lib/heap** - Memory allocators
   - Buddy allocator
   - Slab allocator

### Phase 3: System Libraries (Medium-High Risk)

6. **kernel/lib/crypto** - Cryptographic primitives
   - Hashing (SHA-256)
   - Random number generation

7. **kernel/lib/version** - Version string handling

8. **kernel/lib/debuglog** - Debug logging

### Phase 4: Kernel Subsystems (High Risk, High Complexity)

9. **kernel/object** - Kernel objects
   - Process, Thread
   - VMO, VMAR
   - Port, Channel

10. **kernel/vm** - Virtual memory manager
    - Page allocator
    - Address space management
    
11. **kernel/dev** - Device subsystem
    - MMIO, Interrupts
    - Driver framework

### Deferred: High Complexity or Platform-Specific

- **kernel/arch** - Architecture-specific code (inline assembly, requires per-arch translation)
- **kernel/platform** - Board-specific initialization
- **kernel/dev/interrupt** - Low-level interrupt handling

## Best Practices

### DO

- ✅ Translate one subsystem at a time
- ✅ Run dry-run first to preview issues
- ✅ Review and manually fix translated code
- ✅ Write tests for translated subsystems
- ✅ Keep C and V versions side-by-side during transition
- ✅ Document translation decisions and workarounds

### DON'T

- ❌ Translate all subsystems at once
- ❌ Blindly trust c2v output without review
- ❌ Remove original C code until V version is proven
- ❌ Translate platform-specific code without special care
- ❌ Skip testing translated code

## Troubleshooting

### V toolchain not found

**Error**: `V binary not found at .build-tools/v/v`

**Solution**: 
```bash
./tools/soliloquy/c2v_pipeline.sh --bootstrap-only
```

### c2v translation fails

**Error**: `c2v translation had issues`

**Solution**: c2v may not handle all C constructs. Review the generated V code and fix manually. Common issues:
- Complex macros → Rewrite as functions
- Inline assembly → Use V's assembly syntax or keep as C
- Unions → Use V's sum types or unsafe pointers

### Build fails with translated code

**Error**: Compilation errors in translated V code

**Solution**: 
1. Check V syntax errors
2. Verify types match between C and V
3. Ensure all dependencies are translated or available
4. Use V's FFI to call remaining C code if needed

### GN/Bazel can't find v_rules

**Error**: `Unknown import: //build/v_rules.gni`

**Solution**: Make sure you're on the correct branch and have pulled latest changes:
```bash
git checkout feature/zircon-c2v-subsystems
git pull origin feature/zircon-c2v-subsystems
```

## Technical Details

### c2v Translation Process

1. **Parse**: c2v parses C source with a C parser
2. **AST**: Builds abstract syntax tree
3. **Transform**: Maps C constructs to V equivalents
4. **Generate**: Emits V source code

### Mapping C to V

| C Construct | V Equivalent | Notes |
|-------------|--------------|-------|
| `int`, `char` | `int`, `u8` | V uses explicit sizes |
| `struct` | `struct` | Similar syntax |
| `typedef` | `type` alias | V type aliases |
| `enum` | `enum` | V enums are type-safe |
| `union` | Sum type or `union` | V has safe sum types |
| `void*` | `voidptr` | V supports unsafe pointers |
| `malloc`/`free` | V's allocator | V has memory management |
| Pointer arithmetic | Array indexing | V prefers bounds-checked access |
| Macros | Functions/constants | V doesn't have macros |

### Build System Integration

Both GN and Bazel rules:
1. Call `v_compile.py` or `v_translate.py` wrapper scripts
2. Pass source files, flags, and output paths
3. Invoke `v translate` or `v compile` commands
4. Generate object files or translated V sources

The wrapper scripts handle error cases where c2v can't fully translate code, generating stub files for manual completion.

## Future Work

- **Automated Testing**: CI pipeline for translated subsystems
- **Incremental Translation**: Translate and test file-by-file within subsystems
- **Performance Benchmarks**: Compare C vs V performance
- **V Kernel Modules**: Native V kernel module support
- **Cross-Language Debugging**: Tools for debugging mixed C/V code

## References

- [V Language Documentation](https://github.com/vlang/v/blob/master/doc/docs.md)
- [c2v Translator](https://github.com/vlang/c2v)
- [Zircon Kernel Documentation](https://fuchsia.dev/fuchsia-src/concepts/kernel)
- [Soliloquy Developer Guide](./dev_guide.md)
