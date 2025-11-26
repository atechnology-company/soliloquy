# Zircon VM Subsystem (V Translation)

This directory contains the V language translation of the Zircon VM subsystem from `third_party/zircon_c/vm/`.

## Translation Process

The V code was generated using the c2v translator and then manually corrected:

```bash
./tools/soliloquy/c2v_pipeline.sh --subsystem third_party/zircon_c/vm --out-dir third_party/zircon_v/vm
```

## Files

- **zircon_vm.v** - Consolidated V module with all VM components
- **pmm_arena.v** - Raw c2v output (reference only)
- **vmo_bootstrap.v** - Raw c2v output (reference only)
- **page_fault.v** - Raw c2v output (reference only)

The production V module is `zircon_vm.v`, which has been corrected for:
- Proper module structure
- Public API exports
- Pointer safety with `unsafe` blocks
- Mutability annotations
- Const definitions instead of macros

## Translation Corrections

### 1. Pointer Arithmetic
**Issue**: C code uses pointer arithmetic for page traversal  
**Solution**: Used array indexing with explicit bounds checking in V

**Before (C)**:
```c
vm_page_t* page = &arena->page_array[i];
```

**After (V)**:
```v
unsafe {
    mut page := &arena.page_array[i]
}
```

### 2. Macro Constants
**Issue**: C preprocessor macros don't exist in V  
**Solution**: Converted to V constants

**Before (C)**:
```c
#define PAGE_SIZE 4096
#define ZX_OK 0
```

**After (V)**:
```v
pub const (
    page_size = 4096
    zx_ok = 0
)
```

### 3. Null Pointer Checks
**Issue**: V requires explicit `unsafe` blocks for nil comparisons  
**Solution**: Wrapped null checks in `unsafe` blocks

**Before (c2v output)**:
```v
if arena == (voidptr(0)) {
```

**After (corrected)**:
```v
if unsafe { arena == nil } {
```

### 4. Double Pointers
**Issue**: C uses `vm_page_t**` for output parameters  
**Solution**: V uses `&&Vm_page_t` with proper dereferencing

**Before (C)**:
```c
zx_status_t pmm_arena_alloc_page(pmm_arena_t* arena, vm_page_t** out_page);
```

**After (V)**:
```v
pub fn pmm_arena_alloc_page(mut arena &Pmm_arena_t, mut out_page &&Vm_page_t) Zx_status_t
```

### 5. Mutability
**Issue**: V requires explicit `mut` for mutable references  
**Solution**: Added `mut` annotations to all modifying functions

### 6. Enum Values
**Issue**: C bitfield enums need explicit casting in V  
**Solution**: Cast enum values to u32 for bitwise operations

**Before (c2v output)**:
```v
if (flags & Page_fault_flags_t.page_fault_flag_write) {
```

**After (corrected)**:
```v
if (flags & u32(Page_fault_flags.write)) != 0 {
```

## ABI Compatibility

The V module maintains C ABI compatibility through:

1. **Memory Layout**: Structs use same field order and alignment as C
2. **Calling Convention**: Functions use default C calling convention
3. **Type Sizes**: V types map directly to C types (u64 = uint64_t, etc.)
4. **External Linkage**: Public functions can be called from C

To use from C:
```c
// V module exports are available via C FFI
extern zx_status_t pmm_arena_init(pmm_arena_t* arena, paddr_t base, size_t size);
```

## Testing

Unit tests are located in `test/vm/` and cover:
- PMM arena allocation/deallocation
- VMO bootstrap and commit
- Page fault handling
- Reference counting

Run tests with:
```bash
v test third_party/zircon_v/vm/
```

Or via build system:
```bash
bazel test //test/vm:zircon_vm_test
```

## Known Limitations

1. **Assembly**: Inline assembly (TLB management) remains in C shims
2. **Atomics**: Reference counting is not atomic (requires V atomic operations)
3. **Performance**: V code may have different optimization characteristics than C

## Future Work

- [ ] Add atomic operations for thread-safe ref counting
- [ ] Implement TLB flush operations in V assembly
- [ ] Performance benchmarking vs C implementation
- [ ] Integration with kernel page fault handler
