# HAL Subsystem V Translation

This directory contains V translations of the Soliloquy HAL subsystem.

## Source

**Original C++ Sources**: `third_party/zircon_c/hal/`  
**Translation Date**: 2024-11-26  
**Translation Method**: Manual C++ → V conversion

## Translation Strategy

Since the original HAL is written in C++ with classes, namespaces, and DDK dependencies, automated c2v translation is not suitable. Instead, we use a manual translation approach:

1. **FFI Bindings**: Create V FFI declarations for Zircon/DDK types
2. **Wrapper Structs**: V structs with methods wrapping C++ functionality
3. **Stub Implementation**: Initial stub implementation for build validation
4. **Gradual Implementation**: Incrementally implement V versions alongside C++

## Files

- **mmio.v** - Memory-mapped I/O operations (Read32, Write32, SetBits32, etc.)
- **sdio.v** - SDIO protocol helpers (ReadByte, WriteByte, DownloadFirmware)
- **clock_reset.v** - Clock and reset control
- **firmware.v** - Firmware loading utilities

## c2v Translation Fixes

The c2v translator encountered several issues with the C++ code:

### 1. C++ Classes and Methods
**Issue**: V doesn't have traditional classes with member functions  
**Fix**: Translated to V structs with methods using method syntax:
```v
struct MmioHelper {
    mmio voidptr  // Opaque pointer to C++ MmioBuffer
}

pub fn (m &MmioHelper) read32(offset u32) u32 {
    // Implementation
}
```

### 2. Namespaces
**Issue**: C++ namespace `soliloquy_hal` not supported in V  
**Fix**: Used V module system - all code in `module hal`

### 3. DDK Dependencies
**Issue**: Dependencies on `ddk::MmioBuffer`, `ddk::SdioProtocolClient`  
**Fix**: Created FFI function declarations for C++ interop:
```v
[typedef]
struct C.ddk__MmioBuffer {}

fn C.mmio_read32(mmio &C.ddk__MmioBuffer, offset u32) u32
fn C.mmio_write32(mmio &C.ddk__MmioBuffer, offset u32, value u32)
```

### 4. Logging
**Issue**: `zxlogf(WARNING, ...)` macro not translatable  
**Fix**: Created V wrapper function for logging

### 5. Type Conversions
**Issue**: C++ static_cast and implicit conversions  
**Fix**: Explicit V type casts where needed

### 6. Inline Functions
**Issue**: C++ inline functions in headers  
**Fix**: Regular V functions (V compiler handles inlining)

## Build Integration

The V HAL is built as separate object files that can be linked with C++ code:

### GN Build
```gn
import("//build/v_rules.gni")

v_object("zircon_v_hal_mmio") {
  sources = [ "mmio.v" ]
  output_name = "hal_mmio"
}

group("zircon_v_hal") {
  deps = [
    ":zircon_v_hal_mmio",
    ":zircon_v_hal_sdio",
    ":zircon_v_hal_clock_reset",
    ":zircon_v_hal_firmware",
  ]
}
```

### Bazel Build
```python
load("//build:v_rules.bzl", "v_object")

v_object(
    name = "zircon_v_hal_mmio",
    srcs = ["mmio.v"],
    output_name = "hal_mmio",
)
```

## Testing

The V HAL implementations are validated by:
1. **Build Validation**: V code compiles to object files
2. **C++ Tests**: Existing HAL tests in `drivers/common/soliloquy_hal/tests/` remain green
3. **Gradual Migration**: C++ code continues to use C++ HAL, V code can use V HAL

## Future Work

- **Full Implementation**: Currently stubs, need full implementation of HAL functions
- **Direct FFI**: Create proper V bindings for DDK/Zircon APIs
- **Performance Testing**: Compare V vs C++ HAL performance
- **Test Coverage**: Add V-specific tests for HAL functions
