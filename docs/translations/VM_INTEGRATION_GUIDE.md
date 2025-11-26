# VM Subsystem Integration Guide

Quick start guide for using the translated VM subsystem in your builds.

## Quick Verification

```bash
# Verify the translation is complete
./verify_vm_translation.sh
```

Expected output: All 8 checks pass ✅

## Running Tests

### Fastest: Standalone Tests
```bash
./test/vm/run_tests.sh
```

### With Bazel
```bash
bazel test //test/vm:tests
```

### With GN
```bash
gn gen out/test
ninja -C out/test vm_test
out/test/vm_test
```

## Using in Your Build

### Option 1: Use C Implementation (Default)

The C implementation is the default. No changes needed.

In GN/BUILD.gn:
```gn
executable("my_kernel") {
  deps = [
    "//third_party/zircon_c/vm:zircon_c_vm",
    # ... other deps
  ]
}
```

In Bazel/BUILD.bazel:
```python
cc_binary(
    name = "my_kernel",
    deps = [
        "//third_party/zircon_c/vm:zircon_c_vm",
        # ... other deps
    ],
)
```

### Option 2: Use V Implementation

To use the V-translated implementation:

1. Edit `boards/arm64/soliloquy/board_config.gni`:
   ```gn
   use_v_vm = true  # Change from false to true
   ```

2. Build as normal:
   ```bash
   gn gen out/default
   ninja -C out/default
   ```

The `kernel_vm_deps` variable will automatically select the V implementation.

### Option 3: Mixed C/V Build

For gradual migration, you can use C for some components and V for others:

```gn
executable("my_kernel") {
  deps = [
    "//third_party/zircon_c/vm:zircon_c_vm",  # C PMM
    "//third_party/zircon_v/vm:zircon_v_vm",  # V components
  ]
}
```

Note: This requires careful ABI compatibility management.

## Translating Additional Subsystems

Use the c2v pipeline for other subsystems:

```bash
# 1. Bootstrap V if not done already
./tools/soliloquy/c2v_pipeline.sh --bootstrap-only

# 2. Preview translation
./tools/soliloquy/c2v_pipeline.sh --subsystem kernel/lib/libc --dry-run

# 3. Execute translation
./tools/soliloquy/c2v_pipeline.sh --subsystem kernel/lib/libc --out-dir out/c2v/libc

# 4. Review and correct the output
# Edit out/c2v/libc/*.v files

# 5. Create build targets
# Add BUILD.gn and BUILD.bazel files

# 6. Write tests
# Create test/libc/ with test suite

# 7. Update board config
# Add to board_config.gni like VM subsystem
```

## API Reference

### C API

```c
// PMM Arena
zx_status_t pmm_arena_init(pmm_arena_t* arena, paddr_t base, size_t size);
zx_status_t pmm_arena_alloc_page(pmm_arena_t* arena, vm_page_t** out_page);
zx_status_t pmm_arena_free_page(pmm_arena_t* arena, vm_page_t* page);
size_t pmm_arena_free_count(pmm_arena_t* arena);

// VMO Bootstrap
zx_status_t vmo_bootstrap_init(vmo_t* vmo, pmm_arena_t* arena, size_t size);
zx_status_t vmo_bootstrap_commit_page(vmo_t* vmo, pmm_arena_t* arena, size_t page_index);
void vmo_bootstrap_destroy(vmo_t* vmo, pmm_arena_t* arena);

// Page Fault Handler
zx_status_t page_fault_handler_init(page_fault_handler_t* handler, vmo_t* vmo, pmm_arena_t* arena);
zx_status_t page_fault_handle(page_fault_handler_t* handler, vaddr_t fault_addr, uint32_t flags);
```

### V API

The V module `zircon_vm` exports the same functions with V syntax:

```v
import zircon_vm

// PMM Arena
mut arena := zircon_vm.Pmm_arena_t{}
status := zircon_vm.pmm_arena_init(mut &arena, 0x1000000, 4096 * 100)

// VMO Bootstrap
mut vmo := zircon_vm.Vmo_t{}
status := zircon_vm.vmo_bootstrap_init(mut &vmo, &arena, 4096 * 10)

// Page Fault Handler
mut handler := zircon_vm.Page_fault_handler_t{}
status := zircon_vm.page_fault_handler_init(mut &handler, &vmo, &arena)
```

## Troubleshooting

### Tests Fail
```bash
# Ensure C code compiles
gcc -c third_party/zircon_c/vm/*.c -I third_party/zircon_c/vm/
# Should produce no errors

# Check test logs
./test/vm/run_tests.sh
```

### V Toolchain Issues
```bash
# Re-bootstrap V
rm -rf .build-tools/v
./tools/soliloquy/c2v_pipeline.sh --bootstrap-only

# Verify V is working
.build-tools/v/v version
```

### Build Target Not Found
```bash
# Verify build files exist
ls third_party/zircon_c/vm/BUILD.gn
ls third_party/zircon_v/vm/BUILD.gn

# Check GN args
gn args out/default --list | grep vm
```

## Performance Notes

The V implementation maintains C ABI compatibility and should have similar performance characteristics:

- Same memory layout and struct sizes
- Same calling conventions
- No FFI overhead (native V code)
- Compiler optimizations apply

For production use, benchmark both implementations to verify performance requirements are met.

## Next Steps

1. ✅ VM subsystem translated and tested
2. Consider translating kernel/lib/libc next (see docs/zircon_c2v.md)
3. Run performance benchmarks comparing C vs V
4. Add atomic operations to V implementation
5. Integrate with actual kernel page fault handler

## Support

- Documentation: `docs/zircon_c2v.md`
- Translation Report: `VM_TRANSLATION_REPORT.md`
- Test Coverage: `test/vm/README.md`
- V Translation Details: `third_party/zircon_v/vm/README.md`
