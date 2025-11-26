# Zircon C-to-V Translation Guide

This document provides a comprehensive guide to the C-to-V translation work for Zircon subsystems in the Soliloquy OS project.

## Overview

The Soliloquy OS project includes an experimental effort to translate critical Zircon kernel subsystems from C/C++ to the V programming language. This translation aims to improve memory safety and code maintainability while preserving compatibility with existing systems.

## Translation Strategy

### Manual vs Automated Translation

The `c2v` tool (V's automated C-to-V translator) has limitations:
- **Works well**: Simple C code, basic structs, standard library functions
- **Struggles with**: C++ classes/templates, complex macros, inline assembly, intrusive data structures

For this project, we use a **hybrid approach**:
1. Run `c2v` to generate initial V code
2. Manually review and fix translation issues
3. Document translation decisions and patterns
4. Create FFI bindings for C++ interop where needed

### FFI Integration

V code can call C/C++ functions via Foreign Function Interface (FFI):

```v
// Declare C function
fn C.my_c_function(arg1 int, arg2 voidptr) int

// Call from V
result := C.my_c_function(42, ptr)
```

This allows V code to use existing C++ DDK and Zircon APIs without full reimplementation.

## Translation Workflow

### 1. Snapshot C/C++ Sources

Create a snapshot of the subsystem in `third_party/zircon_c/<subsystem>/`:

```bash
mkdir -p third_party/zircon_c/<subsystem>
cp <source_files> third_party/zircon_c/<subsystem>/
```

Add a README documenting:
- Source file list
- Upstream revision/commit
- Known translation challenges

### 2. Run c2v Translation

Use the c2v pipeline script:

```bash
./tools/soliloquy/c2v_pipeline.sh \
  --subsystem <name> \
  --sources third_party/zircon_c/<subsystem> \
  --out-dir third_party/zircon_v/<subsystem>
```

Review the generated V code in `third_party/zircon_v/<subsystem>/`.

### 3. Fix Translation Issues

Common issues and fixes:

#### C++ Classes → V Structs

**C++ Code:**
```cpp
class MmioHelper {
public:
    uint32_t Read32(uint32_t offset);
private:
    MmioBuffer* mmio_;
};
```

**V Translation:**
```v
pub struct MmioHelper {
pub mut:
    mmio voidptr
}

pub fn (m &MmioHelper) read32(offset u32) u32 {
    return C.mmio_read32(m.mmio, offset)
}
```

#### Pointer Arithmetic → Array Indexing

**C Code:**
```c
uint8_t* buf = base + offset;
```

**V Translation:**
```v
buf := unsafe { base + offset }  // Must wrap in unsafe block
```

#### Macros → Constants/Functions

**C Code:**
```c
#define BLOCK_SIZE 512
#define MAX(a, b) ((a) > (b) ? (a) : (b))
```

**V Translation:**
```v
const block_size = 512

fn max(a int, b int) int {
    return if a > b { a } else { b }
}
```

#### Null Pointers

**V requires explicit unsafe blocks:**
```v
if unsafe { ptr == nil } {
    return error('Null pointer')
}
```

### 4. Create Build Targets

Add build rules for GN and Bazel.

**GN (BUILD.gn):**
```gn
import("//build/v_rules.gni")

v_object("subsystem_module") {
  sources = [ "module.v" ]
  output_name = "module"
}

group("zircon_v_subsystem") {
  deps = [ ":subsystem_module" ]
}
```

**Bazel (BUILD.bazel):**
```python
load("//build:v_rules.bzl", "v_object")

v_object(
    name = "subsystem_module",
    srcs = ["module.v"],
    output_name = "module",
)

filegroup(
    name = "zircon_v_subsystem",
    srcs = [":subsystem_module"],
)
```

### 5. Document Translation

Create a README in `third_party/zircon_v/<subsystem>/README.md` documenting:
- Translation approach (automated vs manual)
- Key challenges and solutions
- FFI patterns used
- Build instructions
- Testing approach

### 6. Validate

Run verification checks:
- V syntax check: `v -check-syntax file.v`
- Build validation: `bazel build //third_party/zircon_v:target`
- Test existing C++ code still works

## Completed Translations

### HAL Subsystem ✅

**Location**: `third_party/zircon_v/hal/`

**Components**:
- `mmio.v` - Memory-mapped I/O operations
- `sdio.v` - SDIO protocol helpers  
- `clock_reset.v` - Clock and reset control
- `firmware.v` - Firmware loading

**Status**: Fully implemented with FFI to C++ DDK

**Key Decisions**:
- Manual translation (C++ classes not supported by c2v)
- FFI calls to `ddk::MmioBuffer` and `ddk::SdioProtocolClient`
- Opaque `voidptr` for C++ object handles
- V's error handling (`!` operator) for status codes

**Build**: 
```bash
bazel build //third_party/zircon_v:zircon_v_hal
```

**Documentation**: `third_party/zircon_v/hal/README.md`

### VM Subsystem ✅ (Reference Implementation)

**Location**: `third_party/zircon_v/vm/`

**Components**:
- Physical Memory Manager (PMM) arena
- Virtual Memory Object (VMO) bootstrap
- Page fault handler

**Status**: Complete reference implementation (from previous work)

**Documentation**: See VM translation reports in `docs/`

### IPC Subsystem ✅ (Reference Implementation)

**Location**: `third_party/zircon_v/ipc/`

**Components**:
- Handle tables
- Channel endpoints
- Message packets

**Status**: Complete reference implementation (from previous work)

**Documentation**: `third_party/zircon_v/ipc/README.md`

## Translation Patterns

### Pattern 1: FFI Wrapper Struct

Use when calling C++ objects from V:

```v
pub struct Helper {
pub mut:
    cpp_obj voidptr
}

fn C.cpp_function(obj voidptr, arg u32) int

pub fn (h &Helper) method(arg u32) int {
    return C.cpp_function(h.cpp_obj, arg)
}
```

### Pattern 2: Error Handling with Status Codes

V's `!` operator for functions that can fail:

```v
pub fn operation() !int {
    status := C.c_function()
    if status != zx_ok {
        return error('Operation failed')
    }
    return status
}
```

### Pattern 3: Multiple Return Values

V supports returning multiple values (like Go):

```v
pub fn load_data() !(u32, u64, int) {
    mut handle := u32(0)
    mut size := u64(0)
    status := C.load(&handle, &size)
    if status != 0 {
        return error('Load failed'), 0, 0, status
    }
    return handle, size, status
}
```

### Pattern 4: Unsafe Pointer Operations

Pointer arithmetic requires `unsafe` blocks:

```v
pub fn read_buffer(base &u8, offset u64) u8 {
    ptr := unsafe { base + offset }
    return unsafe { *ptr }
}
```

## Subsystem Priority List

### Completed ✅
- ✅ HAL - Hardware Abstraction Layer
- ✅ VM - Virtual Memory (reference)
- ✅ IPC - Inter-Process Communication (reference)

### In Progress 🚧
- None currently

### Planned 📋
1. **kernel/lib/libc** - Standard C library functions
2. **kernel/lib/ktl** - Kernel Template Library
3. **kernel/lib/fbl** - Fuchsia Base Library
4. **kernel/object** - Kernel objects (Process, Thread, VMO)
5. **kernel/dev** - Device subsystem

### Deferred ⏸️
- **kernel/arch** - Architecture-specific (inline assembly)
- **kernel/platform** - Board-specific initialization

## Tools and Scripts

### c2v_pipeline.sh

Bootstrap V toolchain and run translation:

```bash
./tools/soliloquy/c2v_pipeline.sh --help
```

Key options:
- `--bootstrap-only` - Install V toolchain only
- `--subsystem <name>` - Subsystem to translate
- `--sources <path>` - Source directory (overrides default)
- `--out-dir <path>` - Output directory
- `--dry-run` - Preview without executing

### V Build Rules

Integrate V code into build system:
- **GN**: `build/v_rules.gni` (v_object, v_library, c2v_translate)
- **Bazel**: `build/v_rules.bzl` (same functionality)
- **Wrappers**: `build/v_compile.py`, `build/v_translate.py`

### Verification Scripts

- `verify_hal_v_translation.sh` - Verify HAL translation setup
- `verify_vm_translation.sh` - Verify VM translation (reference)
- `verify_c2v_setup.sh` - Verify c2v tooling setup

## Best Practices

### DO ✅

- ✅ Translate one subsystem at a time
- ✅ Document translation decisions
- ✅ Use FFI for C++ interop
- ✅ Keep C and V versions side-by-side
- ✅ Add build targets for both GN and Bazel
- ✅ Test that existing C++ code still works
- ✅ Check V syntax: `v -check-syntax file.v`

### DON'T ❌

- ❌ Translate all subsystems at once
- ❌ Trust c2v output blindly (always review)
- ❌ Remove C code until V version is proven
- ❌ Skip documentation
- ❌ Ignore build integration

## Troubleshooting

### V Toolchain Not Found

**Error**: `V binary not found at .build-tools/v/v`

**Solution**:
```bash
./tools/soliloquy/c2v_pipeline.sh --bootstrap-only
```

### c2v Translation Fails

**Error**: `C2V failed to translate the C files`

**Expected for**:
- C++ code (classes, templates, namespaces)
- Complex macros
- Inline assembly

**Solution**: Use manual translation with FFI bindings

### Build Fails

**Error**: `error: unknown import: //build/v_rules.gni`

**Solution**: Ensure you're on the correct branch with V build rules

### V Syntax Errors

**Common Issues**:
- Missing `pub` on exported functions
- Forgetting `mut` for mutable variables
- Not wrapping pointer operations in `unsafe { }`
- Incorrect error handling (missing `!` or `?`)

**Check syntax**:
```bash
v -check-syntax file.v
```

## References

- [V Language Documentation](https://github.com/vlang/v/blob/master/doc/docs.md)
- [c2v Translator](https://github.com/vlang/c2v)
- [Zircon Kernel Docs](https://fuchsia.dev/fuchsia-src/concepts/kernel)
- [Soliloquy Developer Guide](./dev_guide.md)
- [C2V Workflow Details](./zircon_c2v.md)

## Contributing

When adding new translations:

1. Follow the translation workflow above
2. Document your approach in subsystem README
3. Add build targets for GN and Bazel
4. Create verification script if needed
5. Update this document with your subsystem status
6. Test thoroughly before considering complete

## License

All translated code maintains the original BSD-3-Clause license from the Fuchsia project.
