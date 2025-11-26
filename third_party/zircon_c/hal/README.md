# HAL Subsystem C Sources

This directory contains a snapshot of HAL-focused C/C++ sources from Soliloquy's hardware abstraction layer for c2v translation.

## Upstream Source

**Source Location**: `drivers/common/soliloquy_hal/`  
**Snapshot Date**: 2024-11-26  
**Purpose**: C-to-V translation experiment for HAL subsystem

## File List

### Timer and Time Management
- Currently handled by Zircon time APIs (zx_time_t, zx_clock_get_monotonic, zx_nanosleep)
- Used in: `mmio.cc` (WaitForBit32 polling)

### Interrupt Management
- Currently handled via DDK interrupt protocol
- Not directly implemented in this HAL layer

### MMIO Bootstrap and Operations
- **mmio.cc** - Memory-mapped I/O helper functions
- **mmio.h** - MMIO helper class declaration
- Functions: Read32, Write32, SetBits32, ClearBits32, ModifyBits32, ReadMasked32, WriteMasked32, WaitForBit32

### SDIO Protocol Helpers
- **sdio.cc** - SDIO protocol wrapper implementation
- **sdio.h** - SDIO helper class declaration
- Functions: ReadByte, WriteByte, ReadMultiBlock, WriteMultiBlock, DownloadFirmware

### Clock and Reset Control
- **clock_reset.cc** - Clock gating and reset signal management
- **clock_reset.h** - Clock/Reset helper class declaration
- Functions: EnableClock, DisableClock, AssertReset, DeassertReset

### Firmware Loading
- **firmware.cc** - Firmware loading from system
- **firmware.h** - Firmware loader static methods
- Functions: LoadFirmware (with VMO and size output)

## Translation Notes

### Known Challenges for c2v

1. **C++ Classes**: The HAL uses C++ classes (MmioHelper, SdioHelper, etc.)
   - c2v expects C code, not C++
   - May need manual conversion to C-style interfaces first

2. **Namespaces**: Uses `namespace soliloquy_hal`
   - V uses modules instead of namespaces
   - Will be mapped to V module structure

3. **DDK Dependencies**: Heavy use of Fuchsia DDK types
   - `ddk::MmioBuffer`, `ddk::SdioProtocolClient`
   - May need to define V FFI bindings for these types

4. **Inline Assembly**: None present in this HAL layer

5. **Macros**: Limited macro usage (zxlogf for logging)
   - Should translate to V function calls

6. **Type Conversions**: Uses C++ static_cast and pointer casts
   - V has different type conversion syntax

## V Translation Strategy

Given that these are C++ sources, the translation approach is:

1. **Manual C++ → V Translation**: Instead of automated c2v, manually translate the class-based API to V structs with methods
2. **FFI Bindings**: Create V bindings for DDK types (MmioBuffer, SdioProtocolClient)
3. **Keep Parallel**: Maintain both C++ and V versions during transition
4. **Test Equivalence**: Ensure V version passes same tests as C++ version

## Target V Module Structure

```v
// third_party/zircon_v/hal/mmio.v
module hal

pub struct MmioHelper {
    mmio &MmioBuffer  // FFI reference to C++ MmioBuffer
}

pub fn (m &MmioHelper) read32(offset u32) u32 { ... }
pub fn (m &MmioHelper) write32(offset u32, value u32) { ... }
// ... more methods
```

## Build Integration

After translation, the V HAL will be built as:
- **GN**: `//third_party/zircon_v:zircon_v_hal` (v_library target)
- **Bazel**: `//third_party/zircon_v:zircon_v_hal` (v_library target)

The original C++ HAL in `drivers/common/soliloquy_hal` will optionally link against the V version for gradual migration.
